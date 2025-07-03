import {ethers, deployments} from "hardhat";
import {expect} from "chai";

describe("Test auction", async function () { 
    it("Should be ok", async function () { 
        await main();
    })
});
async function main() {
    await deployments.fixture(["deployNftAuction"]);
    // 1. 部署固定环境 ： deployments.fixture() 是 hardhat-deploy 插件提供的函数，用于在测试环境中重置并部署指定的合约
    // 2. 指定部署标签 ： ["deployNftAuction"] 参数指定了要运行的部署脚本标签。这对应于 deploy/01_deploy_nft_auction.ts 文件末尾的 deployNftAuction.tags = ['deployNftAuction'] 设置
    // 3. 快照功能 ： fixture 会创建一个区块链状态的快照，这样后续的测试可以快速重置到这个状态，而不需要每次都重新部署合约，提高测试效率
    const nftAuctionProxy = await deployments.get("NftAuctionProxy");
    // 1. 获取已部署合约 ： deployments.get() 用于获取已部署合约的信息
    // 2. 指定合约名称 ： "NftAuctionProxy" 是要获取的合约名称，这与 01_deploy_nft_auction.ts 文件中的 await save('NftAuctionProxy', {...}) 相对应
    // 3. 返回合约信息 ：这将返回包含合约地址、ABI 等信息的对象，存储在 nftAuctionProxy 变量中，后续可以用于与合约交互

    // 这两行代码的整体目的是：
    // 1. 在测试环境中部署 NFT 拍卖合约（通过代理模式）
    // 2. 获取已部署的代理合约信息，以便后续的测试可以与该合约进行交互
    // 这是使用 Hardhat 框架进行智能合约测试的标准模式，特别是在使用可升级合约（通过代理模式）时。

    const [signer, buyer] = await ethers.getSigners();
    // 这是调用 ethers.js 库的 getSigners() 方法，该方法返回一个由 Hardhat 环境配置的账户签名者（Signer）数组。在 Hardhat 测试环境中，这些签名者代表了可以用来签署交易和消息的以太坊账户。
    // 这个 signer 通常代表测试的主要账户（默认情况下是部署者账户），后续可以用它来：
    // - 部署合约（如果没有明确指定部署者）
    // - 签署交易
    // - 调用需要签名的合约方法
    // - 获取账户地址（通过 signer.address）

    // 一、 部署ERC721合约 
    const TestERC721 = await ethers.getContractFactory("TestERC721");
    // 这行代码的含义是：
    // 1. 创建合约工厂 ： ethers.getContractFactory() 是 ethers.js 库提供的函数，用于创建一个合约工厂对象
    // 2. 指定合约名称 ： "TestERC721" 是要部署的合约名称，对应于 /contracts/test/TestERC721.sol 文件中定义的合约
    // 3. 返回合约工厂 ：这将返回一个可以用来部署 TestERC721 合约的工厂对象，存储在 TestERC721 变量中
    const testERC721 = await TestERC721.deploy();
    // 这行代码的含义是：
    // 1. 部署合约 ：调用合约工厂的 deploy() 方法，将 TestERC721 合约部署到区块链上
    // 2. 构造函数参数 ：这里没有传入任何参数，因为 TestERC721 合约的构造函数不需要额外参数。从 TestERC721.sol 可以看到构造函数是：
    // - 它在内部初始化了 ERC721 名称为 "Troll"，符号为 "Troll"，并将部署者设置为 Ownable 的所有者
    // - 返回合约实例 ：这将返回一个已部署但尚未确认的合约实例，存储在 testERC721 变量中
    await testERC721.waitForDeployment();
    // 这行代码的含义是：
    // 1. 等待确认 ： waitForDeployment() 方法会等待合约部署交易被区块链确认
    // 2. 确保部署成功 ：这是一个异步操作，使用 await 确保在继续执行后续代码之前，合约已经成功部署到区块链上
    const testERC721Address = await testERC721.getAddress();
    // 获取地址 ： getAddress() 方法用于获取已部署合约的区块链地址
    console.log("testERC721Address", testERC721Address);

    // 二、 调用mint方法铸造NFT 给自己
    for(let i = 0; i < 10; i++){
        await (testERC721 as any).mint(signer.address, i+1);
    }

    const tokenId = 1;
    // 在创建拍卖前，先授权拍卖合约操作NFT
    await testERC721.connect(signer).setApprovalForAll(nftAuctionProxy.address, true);
    // 三、 调用createAuction方法创建拍卖
    const nftAuction = await ethers.getContractAt("NFTAuction", nftAuctionProxy.address);
    await nftAuction.createAuction(
        10,
        ethers.parseEther("0.01"),
        testERC721Address,
        tokenId
    );
    const auction = await nftAuction.auctions(0);
    console.log("拍卖创建成功", auction);

    // 四、角色切换到购买者，购买者购买NFT
    await nftAuction.connect(buyer).placeBid(0, {value: ethers.parseEther("0.02")});

    // 五、 拍卖者结束拍卖
    // 等待10s
    await new Promise(resolve => setTimeout(resolve, 15000));
    // @ts-ignore
    await nftAuction.connect(signer).endAuction(0);

    // 六、 验证拍卖结果
    const auctionResult = await nftAuction.auctions(0);
    console.log("结束拍卖后读取拍卖结果", auctionResult);
    expect(auctionResult.highestBidder).to.equal(buyer.address);
    expect(auctionResult.highestBid).to.equal(ethers.parseEther("0.02"));

    // 七、 验证NFT所有权
    // @ts-ignore
    const owner = await testERC721.ownerOf(tokenId);
    console.log("NFT所有权", owner);
    expect(owner).to.equal(buyer.address);
}
main()
