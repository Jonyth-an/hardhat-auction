// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract NFTAuction {
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

    constructor() {
        admin = msg.sender;
    }

    // 创建拍卖
    function createAuction(uint256 _duration, uint256 _startPrice, address _nftContract, uint256 _tokenId) public {
       require(msg.sender == admin, "Only admin can create auction");
       require(_duration > 1000 * 69, "Duration must be greater than 0");
       require(_startPrice > 0, "Start price must be greater than 0");
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
        require(auction.ended == false && auction.startTime + auction.duration < block.timestamp, "Auction has ended");
        // 判断当前出价是否大于最高价
        require(msg.value > auction.highestBid && msg.value > auction.startPrice, "Bid must be greater than highest bid");
        // 如果之前有最高价，则退回上一个最高价
        if(auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }
        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
    }
}
 