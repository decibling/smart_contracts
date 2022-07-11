// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WalletLocker is Ownable {
    mapping(address => mapping(address => LockInfo)) public tokenMappingUser;
    event LockWallet(
        address tokenAddress,
        uint256 amount,
        uint256 releaseTime,
        uint256 releasePercentage,
        uint256 ratio,
        uint256 duration
    );
    event WithDrew(address tokenAddress);
    /**
        money is the money locked
        release time is time the money is no longer lock
        releasePercentage / ratio is ratio of the monkey will be release in partition of time(duration) until it's complete realsed
    */
    struct LockInfo {
        uint256 amount;
        address tokenAddress;
        uint256 withdrawAmount;
        uint256 releaseTime;
        uint256 releasePercentage;
        uint256 ratio;
        uint256 duration;
    }

    function lock(
        address tokenAddress,
        uint256 amount,
        uint256 releaseTime,
        uint256 releasePercentage,
        uint256 ratio,
        uint256 duration
    ) public payable {
        require(
            tokenMappingUser[tokenAddress][msg.sender].amount == 0,
            "EXISTED"
        );
        require(amount != 0, "AMOUNT_ERROR");
        require(releasePercentage < ratio, "RATIO_ERROR");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        tokenMappingUser[tokenAddress][msg.sender].amount = amount;
        tokenMappingUser[tokenAddress][msg.sender].tokenAddress = tokenAddress;
        tokenMappingUser[tokenAddress][msg.sender].releaseTime = releaseTime;
        tokenMappingUser[tokenAddress][msg.sender]
            .releasePercentage = releasePercentage;
        tokenMappingUser[tokenAddress][msg.sender].ratio = ratio;
        tokenMappingUser[tokenAddress][msg.sender].duration = duration;
    }

    function withDraw(address tokenAddress) public {
        require(
            tokenMappingUser[tokenAddress][msg.sender].amount != 0,
            "NOT_EXISTS"
        );
        require(
            tokenMappingUser[tokenAddress][msg.sender].releaseTime <
                block.timestamp,
            "STILL_YOUNG"
        );
        if (tokenMappingUser[tokenAddress][msg.sender].releasePercentage == 0) {
            uint256 amount = tokenMappingUser[tokenAddress][msg.sender].amount;
            delete tokenMappingUser[tokenAddress][msg.sender];
            IERC20(tokenAddress).transfer(payable(msg.sender), amount);
        } else {
            uint256 remainMoney = tokenMappingUser[tokenAddress][msg.sender]
                .amount -
                tokenMappingUser[tokenAddress][msg.sender].withdrawAmount;
            if (remainMoney == 0) {
                delete tokenMappingUser[tokenAddress][msg.sender];
            } else {
                uint256 releaseAmount = ((((block.timestamp -
                    (tokenMappingUser[tokenAddress][msg.sender].releaseTime)) /
                    tokenMappingUser[tokenAddress][msg.sender].duration) *
                    tokenMappingUser[tokenAddress][msg.sender].amount *
                    tokenMappingUser[tokenAddress][msg.sender]
                        .releasePercentage) /
                    (tokenMappingUser[tokenAddress][msg.sender].ratio));
                if (
                    tokenMappingUser[tokenAddress][msg.sender].amount <
                    releaseAmount
                ) {
                    releaseAmount = tokenMappingUser[tokenAddress][msg.sender]
                        .amount;
                }
                require(
                    releaseAmount >
                        tokenMappingUser[tokenAddress][msg.sender]
                            .withdrawAmount,
                    "WAIT_FOR_NEXT_WITHDRAW"
                );
                uint256 withDrawAmount = tokenMappingUser[tokenAddress][
                    msg.sender
                ].withdrawAmount;
                if (
                    withDrawAmount ==
                    tokenMappingUser[tokenAddress][msg.sender].amount
                ) {
                    delete tokenMappingUser[tokenAddress][msg.sender];
                } else {
                    tokenMappingUser[tokenAddress][msg.sender]
                        .withdrawAmount = releaseAmount;
                    if (
                        releaseAmount ==
                        tokenMappingUser[tokenAddress][msg.sender].amount
                    ) {
                        delete tokenMappingUser[tokenAddress][msg.sender];
                    }
                }
                IERC20(tokenAddress).transfer(
                    payable(msg.sender),
                    releaseAmount - withDrawAmount
                );
            }
        }
    }
}
