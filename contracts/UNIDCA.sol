// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//Interface for REWARD token, that incentivises DCA-ing
interface IREWARD {
    function transfer(address to, uint256 amount) external returns (bool);
}

//Interafce for the Uniswap TWAP oracle
interface IUNIOracle {
    function update() external;

    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
}

//Interace for UniswapV2Router02
interface IUniswapV2Router02 {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function WETH() external pure returns (address);
}

/**
 * @title A DCA contract for UNI/ETH
 * @author Kyran Rawlinson
 * @dev DCA contract to allow spaced swaps of ETH to UNI in specified
 * amounts once a week.
 *
 * This behaviour is incentivised with REWARD tokens which are designated
 * to the user after each swap, but are only sent to the user upon the completion
 * of the DCA over the pre-specified period of weeks.
 * The user also receives any unspent ETH upon completion.
 *
 * The swaps resist price manipulation utilising a Uniswap TWAP oracle.
 *
 * The user can cancel their DCA 'account' at any time, receiving any unspect ETH,
 * however they do not receive any REWARD tokens designated to them.
 *
 * This contract is the owner, and holds the initial supply of REWARD tokens
 */
contract UNIDCA {
    IREWARD public rewardToken;
    IUNIOracle public priceOracle;
    IUniswapV2Router02 public uniswapV2Router02;

    address public wethAddress;
    address public uniAddress;

    struct userAccount {
        uint256 ethBalance;
        uint256 ethValuePerWeek;
        uint256 rewardBalance;
        uint256 totalWeeks;
        uint256 currentWeek;
        uint256 lastSwapTimestamp;
    }

    mapping(address => userAccount) public addressToUserAccount;

    event DCABegun(
        address indexed user,
        uint256 totalWeeks,
        uint256 ethValuePerWeek
    );
    event SwapCompleted(
        address indexed user,
        uint256 ethValueOfSwap,
        uint256 weeksRemaining
    );
    event DCACompleted(address indexed user, uint256 rewardAccrued);
    event AccountClosed(address indexed user, uint256 ethRefundAmount);

    constructor(
        address _rewardToken,
        address _priceOracle,
        address _uniswapV2Router02,
        address _uniAddress
    ) {
        rewardToken = IREWARD(_rewardToken);
        priceOracle = IUNIOracle(_priceOracle);
        uniswapV2Router02 = IUniswapV2Router02(_uniswapV2Router02);
        wethAddress = uniswapV2Router02.WETH();
        uniAddress = _uniAddress;
    }

    /**
     * @dev Checks if msg.sender has an active account
     */
    modifier hasActiveAccount() {
        require(
            addressToUserAccount[msg.sender].totalWeeks >= 2,
            "UNIDCA error: Please create an account via beginDCA"
        );
        _;
    }

    /**
     * @dev User sends ETH and specifies number of weeks over which to DCA,
     * if requirements are passed; the user's account is setup
     * and the initial swap is triggered.
     */
    function beginDCA(uint256 _weeks) external payable {
        require(
            msg.value > 0 && (msg.value / _weeks) >= 0.01 ether,
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

        emit DCABegun(
            msg.sender,
            _weeks,
            addressToUserAccount[msg.sender].ethValuePerWeek
        );
    }

    /**
     * @dev If the user has an active account, and
     * at least a week has passed since previous swap
     * (or this is the first swap during 'beginDCA');
     * then the TWAP oracle is consulted, and the value it
     * returns is then used in the 'market sell' of ETH into
     * UNI in order to protect against price manipulation.
     *
     * If succesulful; the user's account is updated and
     * they are desinated 1 REWARD token.
     *
     * If the swap was the last in the number of swaps
     * specified when the user 'signed up',
     * then the completeDCA function is triggered.
     */
    function swap() public hasActiveAccount {
        require(
            block.timestamp >=
                (addressToUserAccount[msg.sender].lastSwapTimestamp + 1 weeks),
            "UNIDCA error: 1 week must have passed since last swap"
        );

        uint256 ethValue = addressToUserAccount[msg.sender].ethValuePerWeek;

        address[] memory path = new address[](2);
        path[0] = wethAddress;
        path[1] = uniAddress;

        addressToUserAccount[msg.sender].ethBalance -= ethValue;
        addressToUserAccount[msg.sender].rewardBalance += 1;
        addressToUserAccount[msg.sender].currentWeek += 1;
        addressToUserAccount[msg.sender].lastSwapTimestamp = block.timestamp;

        priceOracle.update();
        uint256 amountOut = priceOracle.consult(wethAddress, ethValue);

        uniswapV2Router02.swapExactETHForTokens{value: ethValue}(
            amountOut,
            path,
            msg.sender,
            block.timestamp
        );

        emit SwapCompleted(msg.sender, ethValue, weeksRemaining());

        if (
            addressToUserAccount[msg.sender].currentWeek ==
            addressToUserAccount[msg.sender].totalWeeks
        ) {
            _completeDCA();
        }
    }

    /**
     * @dev Only called within the swap function;
     * sends designated quantity of reward tokens to user,
     * and trigger closeAccount.
     */
    function _completeDCA() private {
        rewardToken.transfer(
            msg.sender,
            addressToUserAccount[msg.sender].rewardBalance * 10**18
        );

        emit DCACompleted(msg.sender, rewardAccrued());

        closeAccount();
    }

    function closeAccount() public hasActiveAccount {
        uint256 ethRefund = addressToUserAccount[msg.sender].ethBalance;
        delete addressToUserAccount[msg.sender];

        if (ethRefund > 0) {
            (bool success, ) = msg.sender.call{value: ethRefund}("");
            require(success, "UNIDCA error: Failed to send Ether refund");
        }

        emit AccountClosed(msg.sender, ethRefund);
    }

    function weeksRemaining() public view hasActiveAccount returns (uint256) {
        return (addressToUserAccount[msg.sender].totalWeeks -
            addressToUserAccount[msg.sender].currentWeek);
    }

    function swapAvailable() external view hasActiveAccount returns (bool) {
        return (block.timestamp >=
            (addressToUserAccount[msg.sender].lastSwapTimestamp + 1 weeks));
    }

    function rewardAccrued() public view hasActiveAccount returns (uint256) {
        return addressToUserAccount[msg.sender].rewardBalance;
    }
}
