// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IREWARD {
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IUNIOracle {
    function update() external;

    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
}

contract UNIDCA {
    IREWARD public rewardToken;
    IUNIOracle public priceOracle;

    constructor(address _rewardToken, address _priceOracle) {
        rewardToken = IREWARD(_rewardToken);
        priceOracle = IUNIOracle(_priceOracle);
    }
}
