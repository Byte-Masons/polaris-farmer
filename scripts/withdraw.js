const {ethers} = require('hardhat');

async function main() {
  const vaultAddress = '0x4d106c1982a425A52aFB58030F2E8AaE0238271E';
  const Vault = await ethers.getContractFactory('ReaperVaultv1_4');
  const vault = Vault.attach(vaultAddress);

  // await new Promise(resolve => setTimeout(resolve, 2000));
  // const signer = await ethers.getSigner();
  // console.log(signer.address);
  // const balance = await vault.balanceOf(signer.address);
  // const balance = ethers.BigNumber.from('82717618775903181342529');
  // console.log(balance);
  // const fraction = balance.mul('5000').div('10000');
  // console.log(fraction);
  // 80% '66174095020722545074023'
  // 70% '57902333143132226939770'
  // 60% '49630571265541908805517'
  // 50% '41358809387951590671264'
  // const fraction = ethers.BigNumber.from('41358809387951590671264');
  await vault.withdrawAll();
  console.log('withdraw complete');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
