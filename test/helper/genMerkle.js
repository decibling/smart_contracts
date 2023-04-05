const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

function createMerkleTree(elements) {
    const hashedElements = elements.map(e => keccak256(e));
    const merkleTree = new MerkleTree(hashedElements, keccak256);
    const merkleRoot = merkleTree.getHexRoot();

    return { merkleTree, merkleRoot };
}

function getMerkleProof(merkleTree, element) {
    const hashedElement = keccak256(element);
    const proof = merkleTree.getHexProof(hashedElement);

    return proof;
}

module.exports = { createMerkleTree, getMerkleProof };
