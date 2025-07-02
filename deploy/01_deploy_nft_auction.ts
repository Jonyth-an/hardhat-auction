import {deployments, upgrades} from 'hardhat'
import fs from 'fs'
import path from 'path'
// @ts-ignore
const deployNftAuction = async ({getNamedAccounts}) => {
  // 获取部署者的地址
  const {deploy, save} = deployments
  const {deployer} = await getNamedAccounts()
  console.log('用户部署地址deployer:', deployer)
  // 获取NftAuction合约实例
  const NftAuction = await ethers.getContractFactory('NFTAuction');

  // 通过代理地址部署合约
  const nftAuctionProxy = await upgrades.deployProxy(NftAuction,[],{
    initializer: 'initialize'
  });
  // 等待合约部署完成 
  await nftAuctionProxy.waitForDeployment();
  const proxyAddress = await nftAuctionProxy.getAddress();
  console.log('代理合约地址:', proxyAddress);
  const implAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);
  console.log('实现合约地址:', implAddress);

  const storePath = path.resolve(__dirname, './.cache/proxyNftAuction.json');

  fs.writeFileSync(
    storePath, 
    // @ts-ignore
    JSON.stringify({
      proxyAddress: proxyAddress,
      implAddress,
      abi: NftAuction.interface.format('json'),
    })
  )

  await save('NftAuctionProxy', {
    abi: NftAuction.interface.format('json'),
    address: proxyAddress,
    args: [],
  })
}

deployNftAuction.tags = ['deployNftAuction']
export default deployNftAuction