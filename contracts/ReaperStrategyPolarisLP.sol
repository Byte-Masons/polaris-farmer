// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./abstract/ReaperBaseStrategyv2.sol";
import "./interfaces/IPolarisRewarder.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @dev Deposit LP in the Polaris MasterCHef. Harvest SPOLAR rewards and recompound.
 */
contract ReaperStrategyPolarisLP is ReaperBaseStrategyv2 {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // 3rd-party contract addresses
    address public constant TRISOLARIS_ROUTER = address(0x2CB45Edb4517d5947aFdE3BEAbF95A582506858B);
    address public constant MASTER_CHEF = address(0xA5dF6D8D59A7fBDb8a11E23FDa9d11c4103dc49f);

    /**
     * @dev Tokens Used:
     * {NEAR} - Required for liquidity routing when doing swaps.
     * {SPOLAR} - Reward token for depositing LP into TShareRewardsPool.
     * {USDC} - Alternative token to charge fees
     * {want} - Address of the LP token. (lowercase name for FE compatibility)
     * {lpToken0} - token 0 of the LP
     * {lpToken1} - token 1 of the LP
     */
    address public constant NEAR = address(0xC42C30aC6Cc15faC9bD938618BcaA1a1FaE8501d);
    address public constant SPOLAR = address(0x9D6fc90b25976E40adaD5A3EdD08af9ed7a21729);
    address public constant USDC = address(0xB12BFcA5A55806AaF64E99521918A4bf0fC40802);
    address public constant want = address(0xADf9D0C77c70FCb1fDB868F54211288fCE9937DF);
    address public constant lpToken0 = SPOLAR;
    address public constant lpToken1 = NEAR;

    /**
     * @dev Paths used to swap tokens:
     * {spolarToNearPath} - to swap {SPOLAR} to {NEAR} (using TRISOLARIS_ROUTER)
     * {spolarToNearPath} - to swap {SPOLAR} to {USDC} (using TRISOLARIS_ROUTER)
     */
    address[] public spolarToNearPath;
    address[] public spolarToUsdcPath;

    /**
     * @dev Polaris variables
     * {poolId} - ID of pool in which to deposit LP tokens
     */
    uint256 public poolId;

    /**
     * @dev Strategy variables
     * {chargeFeesInUsdc} - Can be set to charge fees in USDC
     */
    bool public chargeFeesInUsdc;

    /**
     * @dev Initializes the strategy. Sets parameters and saves routes.
     * @notice see documentation for each variable above its respective declaration.
     */
    function initialize(
        address _vault,
        address[] memory _feeRemitters,
        address[] memory _strategists,
        address[] memory _multisigRoles
    ) public initializer {
        __ReaperBaseStrategy_init(_vault, _feeRemitters, _strategists, _multisigRoles);
        spolarToNearPath = [SPOLAR, NEAR];
        spolarToUsdcPath = [SPOLAR, NEAR, USDC];
        poolId = 1;
        chargeFeesInUsdc = true;
    }

    /**
     * @dev Function that puts the funds to work.
     *      It gets called whenever someone deposits in the strategy's vault contract.
     */
    function _deposit() internal override {
        uint256 wantBalance = IERC20Upgradeable(want).balanceOf(address(this));
        if (wantBalance != 0) {
            IERC20Upgradeable(want).safeIncreaseAllowance(MASTER_CHEF, wantBalance);
            IPolarisRewarder(MASTER_CHEF).deposit(poolId, wantBalance);
        }
    }

    /**
     * @dev Withdraws funds and sends them back to the vault.
     */
    function _withdraw(uint256 _amount) internal override {
        uint256 wantBal = IERC20Upgradeable(want).balanceOf(address(this));
        if (wantBal < _amount) {
            IPolarisRewarder(MASTER_CHEF).withdraw(poolId, _amount - wantBal);
        }

        IERC20Upgradeable(want).safeTransfer(vault, _amount);
    }

    /**
     * @dev Core function of the strat, in charge of collecting and re-investing rewards.
     *      1. Claims {SPOLAR} from the {MASTER_CHEF}.
     *      2. Claims fees for the harvest caller and treasury.
     *      3. Swaps half of {lpToken0} to {lpToken1} using {TRISOLARIS_ROUTER}.
     *      6. Creates new LP tokens and deposits.
     */
    function _harvestCore() internal override {
        _claimRewards();
        _chargeFees();
        _addLiquidity();
        deposit();
    }

    function _claimRewards() internal {
        IPolarisRewarder(MASTER_CHEF).deposit(poolId, 0); // deposit 0 to claim rewards
    }

    /**
     * @dev Helper function to swap tokens given an {_amount}, swap {_path}, and {_router}.
     */
    function _swap(
        uint256 _amount,
        address[] memory _path,
        address _router
    ) internal {
        if (_path.length < 2 || _amount == 0) {
            return;
        }

        IERC20Upgradeable(_path[0]).safeIncreaseAllowance(_router, _amount);
        IUniswapV2Router02(_router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            _path,
            address(this),
            block.timestamp
        );
    }

    function _chargeFees() internal {
        if (chargeFeesInUsdc) {
            _chargeFees(USDC, spolarToUsdcPath);
        } else {
            _chargeFees(NEAR, spolarToNearPath);
        }
    }

    /**
     * @dev Core harvest function.
     *      Charges fees based on the amount of rewards earned
     */
    function _chargeFees(address _feeToken, address[] storage _path) internal {
        uint256 spolarFee = IERC20Upgradeable(SPOLAR).balanceOf(address(this)) * totalFee / PERCENT_DIVISOR;
        _swap(spolarFee, _path, TRISOLARIS_ROUTER);
        IERC20Upgradeable feeToken = IERC20Upgradeable(_feeToken);
        uint256 fee = feeToken.balanceOf(address(this));
        if (fee != 0) {
            uint256 callFeeToUser = (fee * callFee) / PERCENT_DIVISOR;
            uint256 treasuryFeeToVault = (fee * treasuryFee) / PERCENT_DIVISOR;
            uint256 feeToStrategist = (treasuryFeeToVault * strategistFee) / PERCENT_DIVISOR;
            treasuryFeeToVault -= feeToStrategist;

            feeToken.safeTransfer(msg.sender, callFeeToUser);
            feeToken.safeTransfer(treasury, treasuryFeeToVault);
            feeToken.safeTransfer(strategistRemitter, feeToStrategist);
        }
    }

    /**
     * @dev Core harvest function. Adds more liquidity using {SPOLAR} and {NEAR}.
     */
    function _addLiquidity() internal {
        uint256 spolarBalanceHalf = IERC20Upgradeable(SPOLAR).balanceOf(address(this)) / 2;
        _swap(spolarBalanceHalf, spolarToNearPath, TRISOLARIS_ROUTER);
        uint256 spolarBalance = IERC20Upgradeable(SPOLAR).balanceOf(address(this));
        uint256 nearBalance = IERC20Upgradeable(NEAR).balanceOf(address(this));

        if (spolarBalance != 0 && nearBalance != 0) {
            IERC20Upgradeable(SPOLAR).safeIncreaseAllowance(TRISOLARIS_ROUTER, spolarBalance);
            IERC20Upgradeable(NEAR).safeIncreaseAllowance(TRISOLARIS_ROUTER, nearBalance);
            IUniswapV2Router02(TRISOLARIS_ROUTER).addLiquidity(
                SPOLAR,
                NEAR,
                spolarBalance,
                nearBalance,
                0,
                0,
                address(this),
                block.timestamp
            );
        }
    }

    /**
     * @dev Function to calculate the total {want} held by the strat.
     *      It takes into account both the funds in hand, plus the funds in the MasterChef.
     */
    function balanceOf() public view override returns (uint256) {
        (uint256 amount, ) = IPolarisRewarder(MASTER_CHEF).userInfo(poolId, address(this));
        return amount + IERC20Upgradeable(want).balanceOf(address(this));
    }

    /**
     * @dev Returns the approx amount of profit from harvesting.
     *      Profit is denominated in NEAR, and takes fees into account.
     */
    function estimateHarvest() external view override returns (uint256 profit, uint256 callFeeToUser) {
        uint256 pendingReward = IPolarisRewarder(MASTER_CHEF).pendingShare(poolId, address(this));
        uint256 totalRewards = pendingReward + IERC20Upgradeable(SPOLAR).balanceOf(address(this));

        if (totalRewards != 0) {
            profit += IUniswapV2Router02(TRISOLARIS_ROUTER).getAmountsOut(totalRewards, spolarToNearPath)[1];
        }

        profit += IERC20Upgradeable(NEAR).balanceOf(address(this));

        uint256 fee = (profit * totalFee) / PERCENT_DIVISOR;
        callFeeToUser = (fee * callFee) / PERCENT_DIVISOR;
        profit -= fee;
    }

    /**
     * Withdraws all funds leaving rewards behind.
     */
    function _reclaimWant() internal override {
        IPolarisRewarder(MASTER_CHEF).emergencyWithdraw(poolId);
    }

    /**
     * Changes which token fees are charged in.
     */
    function _setChargeFeesInUsdc(bool _chargeFeesInUsdc) external atLeastRole(STRATEGIST) {
        chargeFeesInUsdc = _chargeFeesInUsdc;
    }
}
