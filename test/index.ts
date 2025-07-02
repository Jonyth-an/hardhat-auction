import {ethers, deployments, upgrades } from 'hardhat';
const {expect} = require("chai");
// describe("Starting", async function () { 
//     it("Should deploy the contract", async function () {
//         const Contact = await ethers.getContractFactory("NFTAuction");
//         const contract = await Contact.deploy();
//         await contract.waitForDeployment();
//         await contract.createAuction(
//             100 * 1000,
//             ethers.parseEther("0.00000001"),
//             ethers.ZeroAddress,
//             1
//         );
//         const auction = await contract.auctions(0);
//         console.log("auction", auction);
//     }) 
// })

describe("upgrade", async function () { 
    it("Should deploy the contract", async function () {
        // 使用hardhat deployments 把部署和测试逻辑耦合起来
        // 1. 部署业务合约
        
        await deployments.fixture(["deployNftAuction"]); // 部署合约
        const NftAuctionProxy = await deployments.get("NftAuctionProxy"); // 获取合约信息
        const nftAuction = await ethers.getContractAt("NFTAuction", NftAuctionProxy.address); // 获取合约实例
        // 2. 调用createAuction方法创建拍卖
        await nftAuction.createAuction(
            100 * 1000, 
            ethers.parseEther("0.00000001"),
            ethers.ZeroAddress,
            1
        );
        const auction = await nftAuction.auctions(0);
        console.log("createAuction success", auction);

        const implAddress1 = await upgrades.erc1967.getImplementationAddress(NftAuctionProxy.address);
        console.log("实现合约地址1:", implAddress1);
        // 3. 升级合约
        await deployments.fixture(["upgradeNftAuction"]); // 部署合约
        // 4. 读取合约auction[0]做下对比,如果auction[0]升级完之后还是有值，说明合约状态保持住了
        const auctionV2 = await nftAuction.auctions(0);
        console.log("auctionV2", auctionV2);

        const implAddress2 = await upgrades.erc1967.getImplementationAddress(NftAuctionProxy.address);
        console.log("实现合约地址2:", implAddress2);

        const NFTAuctionV2 = await ethers.getContractAt("NFTAuctionV2", NftAuctionProxy.address); // 获取合约实例
        // 5. 调用helloTest方法测试
        // @ts-ignore
        const hello = await NFTAuctionV2.testHello();
        console.log("hello", hello);
        expect(auctionV2.startTime).to.be.equal(auction.startTime);
        expect(implAddress1).to.be.not.equal(implAddress2);
    })  
})