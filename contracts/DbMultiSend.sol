// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DbMultiSend {
    struct Recipient {
        address addr;
        uint amount;
    }

    address[] addresses;

    function multiSend(Recipient[] memory recipients) public payable {
        ERC20 dbToken = ERC20(0xAa8ADb51329BA9640D86Aa10b0F374d97A7B31d9);
        for(uint i = 0; i < recipients.length; i++) {
            require(recipients[i].amount > 0, "Invalid amount");
            require(dbToken.transferFrom(msg.sender, recipients[i].addr, recipients[i].amount));
        }
    }

    function multiSendEth(Recipient[] memory recipients) public payable {
        for(uint i = 0; i < recipients.length; i++) {
            address payable add = payable(recipients[i].addr);
            add.transfer(msg.value / recipients.length);
        }
        payable(msg.sender).transfer(address(this).balance);
    }
}

