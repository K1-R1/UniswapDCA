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

    struct userAccount {
        uint256 ethBalance;
        uint256 ethValuePerWeek;
        uint256 rewardBalance;
        uint256 totalWeeks;
        uint256 currentWeek;
        uint256 lastSwapTimestamp;
    }

    mapping(address => userAccount) public addressToUserAccount; //only one account

    uint256 public userCounter;

    constructor(address _rewardToken, address _priceOracle) {
        rewardToken = IREWARD(_rewardToken);
        priceOracle = IUNIOracle(_priceOracle);
    }

    function beginDCA(uint256 _weeks) external payable {
        //reentrancy?
        /**
       
        makes first swap
        */
        require(
            (msg.value / _weeks) >= 0.01 ether,
            "UNIDCA error: Minimum swap value in ether is 0.01, reduce number of weeks or increase ETH deposit"
        );
        require(
            _weeks >= 2,
            "UNIDCA error: number of weeks must be at least 2"
        );
        addressToUserAccount[msg.sender] = userAccount({
            ethBalance: msg.value,
            ethValuePerWeek: msg.value / _weeks,
            rewardBalance: 0,
            totalWeeks: _weeks,
            currentWeek: 0,
            lastSwapTimestamp: 0
        });

        swap();
    }
}
