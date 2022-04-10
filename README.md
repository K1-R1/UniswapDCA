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

