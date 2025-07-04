// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// 版本问题，第一时间找官网
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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

        // 参与竞价资产  0x是ETH 其他是ERC20
        address tokenAddress;
    }
    
    // 状态变量
    mapping(uint256 => Auction) public auctions; // 拍卖列表
    uint256 public nextActionId; // 下一个拍卖id
    address public admin; // 管理员;
    // AggregatorV3Interface internal priceETHFeed;

    mapping(address => AggregatorV3Interface) public priceFeeds;


    function initialize() initializer public {
        admin = msg.sender;
    }

    function setPriceETHFeed(address tokenAddress ,address _priceFeed) public {
        // priceETHFeed = AggregatorV3Interface(_priceFeed);
        priceFeeds[tokenAddress] = AggregatorV3Interface(_priceFeed);
    }

    // function getLatestPrice() public returns (int256) {
    //     (
    //         uint80 roundID,
    //         int256 price,
    //         uint startedAt,
    //         uint timeStamp,
    //         uint80 answeredInRound
    //     ) = priceETHFeed.latestRoundData();
    //     // emit PriceUpdated(price);
    //     return price;
    // }
    // ETH -> USD 2553 8829 6950   1个ETH = 2553.88296950 美金
    // USDC -> USD  99987319 -> 0.99987319  一般8个小数点
      function getChainlinkDataFeedLatestAnswer(address tokenAddress) public view returns (int) {
        AggregatorV3Interface priceFeed = priceFeeds[tokenAddress];
        // prettier-ignore
        (
            /* uint80 roundId */,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return answer;
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
           tokenId: _tokenId,
           tokenAddress: address(0)
       });
       nextActionId++;
    }

    // 买家参与买单
    // ERC20也能参加
    function placeBid(uint256 _auctionId, uint256 amount, address _tokenAddress) external payable {
        // 统一的价值尺度
        //  ETH 是多少美金
        //  1个USDC
        Auction storage auction = auctions[_auctionId];

        // 注意：block.timestamp 是当前区块的时间戳，单位是秒, js里面单位是毫秒
        console.log("auction.ended", auction.ended);
        console.log("auction.startTime + auction.duration > block.timestamp", auction.startTime, auction.duration, block.timestamp);
        require(auction.ended == false && auction.startTime + auction.duration > block.timestamp, "Auction has ended");
        
        uint payValue;
        if(_tokenAddress != address(0)){
          payValue = amount * uint(getChainlinkDataFeedLatestAnswer(_tokenAddress));
        } else {
            // 处理ETH  
            // 退回之前的ERC20
          amount = msg.value;
          payValue = amount * uint(getChainlinkDataFeedLatestAnswer(address(0)));
        }
        
        // 如果之前有最高价，则退回上一个最高价
        // if(auction.highestBidder != address(0)) {
        //     payable(auction.highestBidder).transfer(auction.highestBid);
        // }
        uint startPriceValue = auction.startPrice * uint(getChainlinkDataFeedLatestAnswer(_tokenAddress));
        uint highestBidValue = auction.highestBid * uint(getChainlinkDataFeedLatestAnswer(_tokenAddress));
        // 判断当前出价是否大于最高价
        require(payValue >= startPriceValue && payValue > highestBidValue, "Bid must be greater than highest bid");
        // 转移ERC20到合约
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), amount);
        if(auction.tokenAddress == address(0)){
            // 如果上一个买家是ETH,还回去
            payable(auction.highestBidder).transfer(auction.highestBid);
        } else {
            // 退回之前的ERC20
            IERC20(auction.tokenAddress).transfer(auction.highestBidder, auction.highestBid);
        }
        auction.tokenAddress = _tokenAddress;
        auction.highestBid = amount;
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
 