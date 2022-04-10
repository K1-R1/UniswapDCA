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

    #deploy REWARD token
    reward_token = REWARD.deploy(
        {'from': account},
        publish_source=True
    )

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

    # UNIOracle deployed at: 0xE03A30B6518F0b2D4FA15B1a72B0C4783989Bd49
    # REWARD deployed at: 0xFf4A9a3895624C21fDa12B02918B8c6A250f07F4
    # UNIDCA deployed at: 0xC542D6cDb9c29faBe30d6dC4BB7c91ba3E7d8E3e
    