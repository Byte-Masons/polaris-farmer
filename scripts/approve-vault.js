async function main() {
  const vaultAddress = '0x4d106c1982a425A52aFB58030F2E8AaE0238271E';
  const ERC20 = await ethers.getContractFactory('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
  const wantAddress = '0xADf9D0C77c70FCb1fDB868F54211288fCE9937DF';
  const want = await ERC20.attach(wantAddress);
  await want.approve(vaultAddress, ethers.utils.parseEther('9999999999999999999999'));
  console.log('want approved');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
