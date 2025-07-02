import {ethers, upgrades} from 'hardhat'
import path from 'path';
import fs from 'fs';

// @ts-ignore
async function upgradeNftAuction({deployments, getNamedAccounts}) {
    const {save} = deployments;
    const {deployer} = await getNamedAccounts();
    console.log('用户部署地址deployer:', deployer);
    // 读取 ./cache/proxyNftAuction.json文件
    const storePath = path.resolve(__dirname, './.cache/proxyNftAuction.json');
    const store = JSON.parse(fs.readFileSync(storePath, 'utf-8'));
    const {proxyAddress, abi, implAddress} = store;

    // 升级版业务合约
    const NFTAuctionV2 = await ethers.getContractFactory('NFTAuctionV2');
    const nftAuctionProxy = await upgrades.upgradeProxy(proxyAddress, NFTAuctionV2);
    await nftAuctionProxy.waitForDeployment();
    const proxyAddressV2 = await nftAuctionProxy.getAddress();

    // fs.writeFileSync(
    //     storePath,
    //     JSON.stringify({
    //         proxyAddress: proxyAddressV2,
    //         implAddress,
    //         abi,
    //     })
    // )

    await save('NFTAuctionV2', {
        address: proxyAddressV2,
        abi,
    })
}

upgradeNftAuction.tags = ['upgradeNftAuction']
export default upgradeNftAuction