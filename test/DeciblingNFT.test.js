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
        it("Should mint a new NFT with the correct name and URI", async function () {
            const proof = []
            const name = "Test Audio";
            const uri = "https://example.com/testaudio";
            await deciblingNFT.connect(owner).mint(proof, name, uri);

            const tokenId = 0;
            expect(await deciblingNFT.ownerOf(tokenId)).to.equal(owner.address);
            expect(await deciblingNFT.audioInfos(tokenId)).to.equal(name);
            expect(await deciblingNFT.tokenURI(tokenId)).to.equal(uri);
        });

        it("Should fail to mint a new NFT with an empty name", async function () {
            const proof = []
            const name = "";
            const uri = "https://example.com/testaudio";
            await expect(deciblingNFT.connect(owner).mint(proof, name, uri)).to.be.revertedWith("28");
        });
    });

    // describe("Minting from artists", function () {
    //     it("Should fail mint NFT if not on the list", async function () {
    //         let root = buildTree([
    //             [owner.address],
    //             [addr1.address],
    //         ]);

    //         expect(await deciblingNFT.connect(owner).setMerkleRoot(root))

    //         const name = "test";
    //         const uri = "https://example.com/testaudio";
    //         expect(await deciblingNFT.connect(addr1).mint(obtainProof(addr1.address), name, uri));
    //     });
    // });

    // describe("Upgrading", function () {
    //     it("Should be able to upgrade the contract", async function () {
    //         const newImplementation = await ethers.getContractFactory("DeciblingNFT");
    //         await upgrades.prepareUpgrade(deciblingNFT.address, newImplementation);
    //     });
    // });
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
        const name = "Valid Audio";
        const uri = "https://ipfs.io/ipfs/VALID_AUDIO";

        await expect(deciblingNFT.connect(addr1).mint(validProof, name, uri))
            .to.emit(deciblingNFT, "Minted")
            .withArgs(name, 0);

        const audioInfo = await deciblingNFT.audioInfos(0);
        console.log("🚀 ~ file: DeciblingNFT.test.js:137 ~ it ~ audioInfo:", audioInfo)
        expect(audioInfo).to.equal(name);

        const tokenURI = await deciblingNFT.tokenURI(0);
        expect(tokenURI).to.equal(uri);
    });

    it("Mint with invalid proof", async () => {
        const name = "Invalid Audio";
        const uri = "https://ipfs.io/ipfs/INVALID_AUDIO";

        await expect(deciblingNFT.connect(addr1).mint(invalidProof, name, uri)).to.be.revertedWith("Invalid proof");
    });
});