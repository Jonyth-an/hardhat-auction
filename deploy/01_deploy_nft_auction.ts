import {deployments, upgrades} from 'hardhat'

const deployNftAuction = async () => {
  const {deploy} = deployments
  const {deployer} = await deployments.getNamedAccounts()
  await deploy('NftAuction', {
    from: deployer,
    args: [],
    log: true,
  })
}

const tags = ['deployNftAuction']
export default tags