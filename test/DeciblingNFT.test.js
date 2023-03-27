const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");

describe.only("DeciblingNFT", function () {
    let DeciblingNFT, deciblingNFT, owner, addr1;

    beforeEach(async function () {
        DeciblingNFT = await ethers.getContractFactory("DeciblingNFT");
        deciblingNFT = await upgrades.deployProxy(DeciblingNFT, [], { initializer: "initialize" });
        [owner, addr1] = await ethers.getSigners();
    });

    describe("Deployment", function () {
        it("Should set the correct name and symbol", async function () {
            expect(await deciblingNFT.name()).to.equal("Decibling");
            expect(await deciblingNFT.symbol()).to.equal("dB");
        });
    });

    describe("Minting", function () {
        it("Should mint a new NFT with the correct name and URI", async function () {
            const name = "Test Audio";
            const uri = "https://example.com/testaudio";
            await deciblingNFT.connect(owner).mint(name, uri);

            const tokenId = 0;
            expect(await deciblingNFT.ownerOf(tokenId)).to.equal(owner.address);
            expect(await deciblingNFT.audioInfos(tokenId)).to.equal(name);
            expect(await deciblingNFT.tokenURI(tokenId)).to.equal(uri);
        });

        it("Should fail to mint a new NFT with an empty name", async function () {
            const name = "";
            const uri = "https://example.com/testaudio";
            await expect(deciblingNFT.connect(owner).mint(name, uri)).to.be.revertedWith("28");
        });
    });

    describe("Upgrading", function () {
        it("Should be able to upgrade the contract", async function () {
            const newImplementation = await ethers.getContractFactory("DeciblingNFT");
            await upgrades.prepareUpgrade(deciblingNFT.address, newImplementation);
        });
    });
});
