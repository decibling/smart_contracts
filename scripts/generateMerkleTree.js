const {
    StandardMerkleTree
} = require("@openzeppelin/merkle-tree");
const fs = require('fs');

function buildTree() {
    // (1)
    const values = [
        ["0x1111111111111111111111111111111111111111"],
        ["0x1111111111111111111111111111111111111112"],
        ["0x1111111111111111111111111111111111111113"]
    ];

    // (2)
    const tree = StandardMerkleTree.of(values, ["address"]);

    // (3)
    console.log('Merkle Root:', tree.root);

    // (4)
    fs.writeFileSync("tree.json", JSON.stringify(tree.dump()));
}

function obtainProof() {
    // (1)
    const tree = StandardMerkleTree.load(JSON.parse(fs.readFileSync("tree.json")));

    // (2)
    for (const [i, v] of tree.entries()) {
        if (v[0] === '0x1111111111111111111111111111111111111111') {
            // (3)
            const proof = tree.getProof(i);
            console.log('Value:', v);
            console.log('Proof:', proof);
        }
    }
}

buildTree()
obtainProof()