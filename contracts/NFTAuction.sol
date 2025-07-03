// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract NFTAuction is Initializable, UUPSUpgradeable {
    struct Auction {
        address seller; // 卖家;
        uint256 duration; // 拍卖时长
        uint256 startPrice; // 起始价格 
        // 开始时间
        uint256 startTime;

        bool ended; // 是否结束
        address highestBidder; // 最高出价人
        uint256 highestBid; // 最高出价

        address nftContract; // nft合约地址
        uint256 tokenId; // nft id
    }

    // 状态变量
    mapping(uint256 => Auction) public auctions; // 拍卖列表
    uint256 public nextActionId; // 下一个拍卖id
    address public admin; // 管理员;

    function initialize() initializer public {
        admin = msg.sender;
    }

    // 创建拍卖
    function createAuction(uint256 _duration, uint256 _startPrice, address _nftContract, uint256 _tokenId) public {
       require(msg.sender == admin, "Only admin can create auction");
       require(_duration >= 10, "Duration must be greater than 10s");
       require(_startPrice > 0, "Start price must be greater than 0");

       // 用于授权合约操作NFT
       IERC721(_nftContract).approve(address(this), _tokenId);
       // 行代码的含义是：
       // 1. 它在 createAuction 函数中，用于授权合约操作NFT
       // 2. 具体解释：
       //    - IERC721(_nftContract) - 将地址 _nftContract 转换为IERC721接口类型，这是与ERC721标准（非同质化代币/NFT标准）交互的方式
       //    - .approve - 调用ERC721标准中的授权函数
       //    - address(this) - 当前合约的地址，即NFTAuction合约
       //    - _tokenId - 要拍卖的NFT的唯一标识符
       // 3. 这行代码的作用是授权拍卖合约操作指定的NFT。通过approve函数，NFT的所有者（msg.sender，即创建拍卖的用户）授权拍卖合约（address(this)）可以转移特定的NFT（_tokenId）。
       // 这行代码的作用是将NFT从卖家转移到拍卖合约中托管，这样在拍卖期间，NFT由合约持有，确保拍卖结束后能够正确地将NFT转移给最高出价者。
      //    IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenId);

       auctions[nextActionId] = Auction({
           seller: msg.sender,
           duration: _duration,
           startPrice: _startPrice,
           ended: false,
           highestBidder: address(0),
           highestBid: 0,
           startTime: block.timestamp,
           nftContract: _nftContract,
           tokenId: _tokenId
       });
       nextActionId++;
    }

    // 买家参与买单
    function placeBid(uint256 _auctionId) external payable { 
        Auction storage auction = auctions[_auctionId];

        // 注意：block.timestamp 是当前区块的时间戳，单位是秒, js里面单位是毫秒
        console.log("auction.ended", auction.ended);
        console.log("auction.startTime + auction.duration > block.timestamp", auction.startTime, auction.duration, block.timestamp);
        require(auction.ended == false && auction.startTime + auction.duration > block.timestamp, "Auction has ended");
        // 判断当前出价是否大于最高价
        require(msg.value > auction.highestBid && msg.value > auction.startPrice, "Bid must be greater than highest bid");
        // 如果之前有最高价，则退回上一个最高价
        if(auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }
        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
    }

    // 结束拍卖
    function endAuction(uint256 _auctionId) external {
        Auction storage auction = auctions[_auctionId];
        // 分别打印结构体中的各个字段
        console.log("endAuction seller:", auction.seller);
        console.log("endAuction duration:", auction.duration);
        console.log("endAuction startPrice:", auction.startPrice);
        console.log("endAuction startTime:", auction.startTime);
        console.log("endAuction ended:", auction.ended);
        console.log("endAuction highestBidder:", auction.highestBidder);
        console.log("endAuction highestBid:", auction.highestBid);
        console.log("endAuction nftContract:", auction.nftContract);
        console.log("endAuction tokenId:", auction.tokenId);
        
        // 修改条件判断逻辑
        require(auction.ended == false, "Auction already ended");
        require(auction.startTime + auction.duration < block.timestamp, "Auction time not expired");
        
        // 转移NFT到最高出价者
        IERC721(auction.nftContract).safeTransferFrom(admin, auction.highestBidder, auction.tokenId);
        // 转移剩余金额到卖家
        // payable(address(this)).transfer(address(this).balance);
        auction.ended = true;
    }

    function _authorizeUpgrade(address newImplementation) internal override view{
        // 只有管理员可以升级合约
        require(msg.sender == admin, "Only admin can upgrade contract");
    }
}
 