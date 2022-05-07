async function main() {
  const vaultAddress = '0x0aD9E4D7ef01208fC1e67eD5C3136bEc11d00aaD';
  const Vault = await ethers.getContractFactory('ReaperVaultv1_4');
  const vault = Vault.attach(vaultAddress);
  await vault.depositAll();
  console.log('deposit complete');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
