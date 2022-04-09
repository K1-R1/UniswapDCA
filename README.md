# UniswapDCA

Create a smart contract which helps users execute a dollar-cost averaging approach to investing
in a single ERC20 token with ether. The contract should:

1. Accept one-time ether payment

2. Allow spaced conversions of ether into a single ERC20 token over a fixed time period
a. Bonus: incentivize these conversions

3. Conversions should happen via Uniswap V2 and be executed as “market sells” of ether for
the ERC20 token
a. Bonus: resists price manipulation

---------------

/**
deposit
    takes in ETH, how many trades
    sets up user account
        ETH balance
        number of trades to be made
            such that min trade is >=0.01 ETH value
        ETH value of each trade
        REWARD to be paid
        number of trades made
        timestamp of last trade
    makes first swap

swap
    if now > timestamp of last trade + 1 week
        market sell ETH for UNI
            using oracle
        send UNI to user
        update user account
            add to REWARD balance
        check if user's DCA is complete
            trigger complete func

complete
    refunds remaining ETH balance
    transfers REWARD tokens
    deletes user account

cancel
    refunds remaining ETH balance
    deletes user account

helper funcs
    swaps remainig
    swap avaiable
    rewards acrued
 */