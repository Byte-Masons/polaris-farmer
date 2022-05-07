async function main() {
  const vaultAddress = '0x0aD9E4D7ef01208fC1e67eD5C3136bEc11d00aaD';
  const strategyAddress = '0x8df864Aa8cd79C14Bc7d939cC6ED1EddBBEC7Dbe';

  const Vault = await ethers.getContractFactory('ReaperVaultv1_4');
  const vault = Vault.attach(vaultAddress);

  await vault.initialize(strategyAddress);
  console.log('Vault initialized');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
