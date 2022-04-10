from brownie import config, accounts, UNIDCA, REWARD, UNIOracle

def main():
    deploy()

def deploy():
    account = accounts.add(config['wallets']['dev_account_1']['private_key'])

    #deploy UNIoracle
    uni_oracle = UNIOracle.deploy(
        '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f',
        '0xc778417E063141139Fce010982780140Aa0cD5Ab',
        '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984',
        {'from': account},
        publish_source=True
    )
    print(uni_oracle.address)

    #deploy REWARD token
    reward_token = REWARD.deploy(
        {'from': account},
        publish_source=True
    )
    print(reward_token.address)

    #deploy DCA
    uni_dca = UNIDCA.deploy(
        reward_token.address,
        uni_oracle.address,
        '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D',
        '0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984',
        {'from': account},
        publish_source=True,
    )

    #transfer ownership of REWARD to DCA
    reward_token.setupNewOwner(
        uni_dca.address,
        {'from': account}
    ).wait(1)

    # UNIOracle deployed at: 0x01e6884511D0993bf097bee8DA6DDA21BEae6f4d
    # REWARD deployed at: 0x2b5094A4286Dc094A9581BC1fc8f272b2a2a85c1
    # UNIDCA deployed at: 0x3eB002DD8B2b30843db048eD403219022007D1AA
    