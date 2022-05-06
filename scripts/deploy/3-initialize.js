async function main() {
  const vaultAddress = '0x4d106c1982a425A52aFB58030F2E8AaE0238271E';
  const strategyAddress = '0xA6a115FC9B0A4e0A04040ae6A6497314250816a8';

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
