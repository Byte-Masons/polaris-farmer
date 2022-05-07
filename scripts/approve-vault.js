async function main() {
  const vaultAddress = '0x80a79d0Fe8c658bC2aE7bD37Fc48a74D59803A5F';
  const ERC20 = await ethers.getContractFactory('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
  const wantAddress = '0x3fa4d0145a0b6Ad0584B1ad5f61cB490A04d8242';
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
