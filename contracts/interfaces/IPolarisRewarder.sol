// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPolarisRewarder {
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function pendingShare(uint256 _pid, address _user) external view returns (uint256);

    function deposit(uint256 pid, uint256 amount) external;

    function withdraw(uint256 pid, uint256 amount) external;

    function emergencyWithdraw(uint256 pid) external;
}
