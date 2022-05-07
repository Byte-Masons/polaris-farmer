async function main() {
  const vaultAddress = '0x80a79d0Fe8c658bC2aE7bD37Fc48a74D59803A5F';
  const strategyAddress = '0x9cBfEfc9d08f36Ae67fD2eD4BD4d3688ea25dbc7';

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
