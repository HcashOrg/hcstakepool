stakepoold
====

The goal of stakepoold is to communicate with hcd/hcwallet/hcstakepool via client/server gRPC in order to handle all stakepool functions that are currently in hcwallet or are undefined/unhandled.

## First:

Receive, store, and act on (vote) per-user voting policy from hcstakepool.

#### Steps

1. stakepoold skeleton code with testnet/mainnet flags with per-network vote version
2. wire up stakepoold to get notified of winners, set votebits according to prefs/vote version, ask wallet to sign, send
3. add user voting policy interface to hcstakepool
4. send hcstakepool user voting policy config to stakepoold and store it

## Second:

Rip out all stakepool-related configuration from the wallet. (ticket adding, multisig scripts, fee checking, votebits modification RPCs)

#### Steps

1. Migrate the rest of the stakepool-related functionality from wallet to stakepoold.
2. Modify hcstakepool to cope with changes. hcstakepool should not need to talk to hcwallet directly anymore.