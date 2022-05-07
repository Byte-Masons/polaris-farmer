async function main() {
  const vaultAddress = '0x0aD9E4D7ef01208fC1e67eD5C3136bEc11d00aaD';
  const ERC20 = await ethers.getContractFactory('@openzeppelin/contracts/token/ERC20/ERC20.sol:ERC20');
  const wantAddress = '0x3e50da46cB79d1f9F08445984f207278796CE2d2';
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
