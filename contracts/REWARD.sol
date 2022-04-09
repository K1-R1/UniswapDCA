// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract REWARD is ERC20, Ownable {
    constructor() ERC20("REWARD", "RWD") {
        _mint(msg.sender, 10000000 * 10**decimals());
    }

    function setupNewOwner(address _newOwner) external onlyOwner {
        transfer(_newOwner, balanceOf(owner()));
        transferOwnership(_newOwner);
    }
}
