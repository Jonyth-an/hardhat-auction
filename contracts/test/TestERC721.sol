// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestERC721 is ERC721Enumerable, Ownable {
    string private _tokenURI;

    // 用于在继承多个合约时，同时初始化所有父合约。当一个合约继承多个父合约时，必须在构造函数中指定如何初始化每个父合约（如果父合约的构造函数需要参数）
    constructor() ERC721("Troll", "Troll") Ownable(msg.sender) {}

    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _tokenURI;
    }

    function setTokenURI(string memory newTokenURI) external onlyOwner {
        _tokenURI = newTokenURI;
    }
}