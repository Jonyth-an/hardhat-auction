import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy"
import "@openzeppelin/hardhat-upgrades";
const config: HardhatUserConfig = {
  solidity: "0.8.28",
  namedAccounts: {
    // 标记账户的索引
    deployer: {
      default: 0,
    },
    user1: 1,
    user2: 2,
  },
};

export default config;
