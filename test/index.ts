const {ethers} = require("hardhat")

describe("Starting", async function () { 
    it("Should deploy the contract", async function () {
        const Contact = await ethers.getContractFactory("NFTAuction");
        const contract = await Contact.deploy();
        await contract.waitForDeployment();
        await contract.createAuction(
            100 * 1000,
            ethers.parseEther("0.00000001"),
            ethers.ZeroAddress,
            1
        );
        const auction = await contract.auctions(0);
        console.log("auction", auction);
    }) 
})