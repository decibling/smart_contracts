pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeciblingToken is ERC20, Ownable {
    constructor() public ERC20("Froggily", "FROY") {
        _mint(msg.sender, 100000000000000000000000000000);
    }
}
