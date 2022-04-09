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

interface IUniswapV2Router02 {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

contract UNIDCA {
    IREWARD public rewardToken;
    IUNIOracle public priceOracle;
    IUniswapV2Router02 public uniswapV2Router02;

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

    constructor(
        address _rewardToken,
        address _priceOracle,
        address _uniswapV2Router02
    ) {
        rewardToken = IREWARD(_rewardToken);
        priceOracle = IUNIOracle(_priceOracle);
        uniswapV2Router02 = IUniswapV2Router02(_uniswapV2Router02);
    }

    function beginDCA(uint256 _weeks) external payable {
        //reentrancy check?
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
        //event
    }

    function swap() public {
        /**
        if now > timestamp of last trade + 1 week
            market sell ETH for UNI
                using oracle
            send UNI to user
            update user account
                add to REWARD balance
            check if user's DCA is complete
                trigger complete func
         */
        require(
            block.timestamp >=
                (addressToUserAccount[msg.sender].lastSwapTimestamp + 1 weeks),
            "UNIDCA error: 1 week must have passed since last swap"
        );
    }
}
