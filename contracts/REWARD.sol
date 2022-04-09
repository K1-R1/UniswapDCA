// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract REWARD is ERC20 {
    constructor() ERC20("REWARD", "RWD") {
        _mint(msg.sender, 10000000 * 10**decimals());
    }
}
