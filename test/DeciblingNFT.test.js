const {
    ethers,
    upgrades
} = require("hardhat");
const {
    expect
} = require("chai");
// const {
//     StandardMerkleTree
// } = require("@openzeppelin/merkle-tree");
const fs = require('fs');
const { keccak256 } = require("ethers/lib/utils");
const { createMerkleTree, getMerkleProof } = require("./helper/genMerkle");

// function buildTree(values) {
//     // (1)
//     // (2)
//     const tree = StandardMerkleTree.of(values, ["address"]);
//     // (3)
//     console.log('Merkle Root:', tree.root);
//     // (4)
//     fs.writeFileSync("tree.json", JSON.stringify(tree.dump()));

//     return tree.root;
// }

// function obtainProof(addr) {
//     // (1)
//     const tree = StandardMerkleTree.load(JSON.parse(fs.readFileSync("tree.json")));

//     // (2)
//     for (const [i, v] of tree.entries()) {
//         if (v[0] === addr) {
//             // (3)
//             const proof = tree.getProof(i);
//             console.log('Value:', v);
//             console.log('Proof:', proof);

//             return proof;
//         }
//     }
// }

const jsonPrefix = 'data:application/json;base64,';

describe("DeciblingNFT", function () {
    let DeciblingNFT, deciblingNFT, owner, addr1, addr2, addr3, addr4;

    beforeEach(async function () {
        DeciblingNFT = await ethers.getContractFactory("DeciblingNFT");
        deciblingNFT = await upgrades.deployProxy(DeciblingNFT, [], {
            initializer: "initialize"
        });

        [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
    });

    describe("Deployment", function () {
        it("Should set the correct name and symbol", async function () {
            expect(await deciblingNFT.name()).to.equal("Decibling");
            expect(await deciblingNFT.symbol()).to.equal("dB");
        });
    });

    describe("Minting from owner", function () {
        it("Should mint a new NFT with the correct name and owner", async function () {
            const proof = [];
            const hash = "hashdata";
            const name = "testaudio";
            await deciblingNFT.connect(owner).mint(proof, hash, name);

            const tokenId = 1;
            expect(await deciblingNFT.ownerOf(tokenId)).to.equal(owner.address);
            expect(await deciblingNFT.nftInfos(tokenId)).to.equal(name);

            let dat = await deciblingNFT.tokenURI(tokenId);
            let json = JSON.parse(Buffer.from((dat.substr(jsonPrefix.length)), 'base64'));
            expect(json.hash_sha256).to.equal(hash);
            expect(json.name).to.equal(name);
        });

        it("Should fail to mint a new NFT with an empty name", async function () {
            const proof = [];
            const hash = "hashdata";
            const name = "";
            await expect(deciblingNFT.connect(owner).mint(proof, hash, name)).to.be.revertedWith("Invalid name");
        });
    });
});

describe("DeciblingNFT with Merkle Proof", function () {
    let DeciblingNFT, deciblingNFT, owner, addr1, addr2;
    let merkleTree, merkleRoot, validProof, invalidProof;

    beforeEach(async () => {
        DeciblingNFT = await ethers.getContractFactory("DeciblingNFT");
        [owner, addr1, addr2] = await ethers.getSigners();
        deciblingNFT = await upgrades.deployProxy(DeciblingNFT, { initializer: "initialize" });

        // Generate Merkle Tree, Root, and Proofs
        const elements = [addr1.address, addr2.address];
        const { merkleTree: tree, merkleRoot: root } = createMerkleTree(elements);
        merkleTree = tree;
        merkleRoot = root;
        validProof = getMerkleProof(merkleTree, addr1.address);
        invalidProof = getMerkleProof(merkleTree, owner.address);

        // Set the Merkle Root
        await deciblingNFT.connect(owner).setMerkleRoot(merkleRoot);
    });

    it("Mint with valid proof", async () => {
        const hash = "hashdata";
        const name = "testaudio";

        await expect(deciblingNFT.connect(addr1).mint(validProof, hash, name))
            .to.emit(deciblingNFT, "Minted")
            .withArgs(1);

        const audioInfo = await deciblingNFT.nftInfos(1);
        expect(audioInfo).to.equal(name);
        let dat = await deciblingNFT.tokenURI(1);
        let json = JSON.parse(Buffer.from((dat.substr(jsonPrefix.length)), 'base64'));
        expect(json.hash_sha256).to.equal(hash);
        expect(json.name).to.equal(name);
    });

    it("Mint with invalid proof", async () => {
        const hash = "hashdata";
        const name = "testaudio";

        await expect(deciblingNFT.connect(addr1).mint(invalidProof, hash, name)).to.be.revertedWith("Invalid proof");
    });
});