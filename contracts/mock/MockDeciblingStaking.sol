// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../DeciblingStaking.sol";

contract DeciblingStakingMock is DeciblingStaking {
    constructor(address _tokenAddress, address payable _platformFeeRecipient) DeciblingStaking(_tokenAddress, _platformFeeRecipient) {
        super._newPool("decibling_pool", 3650, 0);
    }
}