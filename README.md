# hcstakepool

[![GoDoc](https://godoc.org/github.com/HcashOrg/hcstakepool?status.svg)](https://godoc.org/github.com/HcashOrg/hcstakepool)
[![Build Status](https://travis-ci.org/HcashOrg/hcstakepool.svg?branch=master)](https://travis-ci.org/HcashOrg/hcstakepool)
[![Go Report Card](https://goreportcard.com/badge/github.com/HcashOrg/hcstakepool)](https://goreportcard.com/report/github.com/HcashOrg/hcstakepool)

hcstakepool is a web application which coordinates generating 1-of-2 multisig
addresses on a pool of [hcwallet](https://github.com/HcashOrg/hcwallet) servers
so users can purchase [proof-of-stake tickets](https://wiki.h.cash/mining/proof-of-stake/)
on the [HC](https://h.cash/) network and have the pool of wallet servers
vote on their behalf when the ticket is selected.

## Architecture

![Stake Pool Architecture](https://raw.githubusercontent.com/HcashOrg/hcstakepool/master/public/images/HC-Coldwallet.jpg)

- It is highly recommended to use 3 hcd+hcwallet+stakepoold nodes for
  production use on mainnet.
- The architecture is subject to change in the future to lessen the dependence
  on hcwallet and MySQL.

## Git Tip Release notes

- The handling of tickets considered invalid because they pay too-low-of-a-fee
is now integrated directly into hcstakepool and stakepoold.
  - Users who pass both the adminIPs and the new adminUserIDs checks will see a new link on the
menu to the new administrative add tickets page.
  - Tickets are added to the MySQL database and then stakepoold is triggered to pull an update from the
database and reload its config.
  - To accommodate changes to the gRPC API, hcstakepool/stakepoold had
  their API versions changed to require/advertize 4.0.0. This requires
  performing the upgrade steps outlined below.

## Git Tip Upgrade Guide

1) Announce maintenance and shut down hcstakepool.
2) Upgrade Go to the latest stable version if necessary/possible.
3) Perform an upgrade of each stakepoold instance one at a time.
   * Stop stakepoold.
   * Build and restart stakepoold.
4) Edit hcstakepool.conf and set adminIPs/adminUserIDs appropriately to include
   the administrative staff for whom you wish give the ability to add low fee
   tickets for voting.
5) Upgrade and start hcstakepool after setting adminUserIDs.
6) Announce maintenance complete after verifying functionality.

## 1.1.1 Release Notes

- hcd has a new agenda and the vote version in hcwallet has been
  incremented to v5 on mainnet.
- stakepoold
  - The ticket list is now maintained by doing an initial GetTicket RPC
  call and then substracts/adds tickets by processing SpentAndMissed/New
  ticket notifications from hcwallet.  This approach is much faster than
  the old method of calling StakePoolUserInfo for each user.
  - Bug fixes to the above commit and to accommodate changes in hcwallet.
- Status page
  - StatusUnauthorized error is now thrown rather than a generic one when
  accessing the page as a non-admin.
  - Updated to use new design.
  - Synced hcwallet walletinfo field list.
- Tickets page
  - Performance was greatly improved by skipping display of historic tickets.
  - Handles users that have only low fee/invalid tickets properly.
  - Expired tickets are now separated from missed.
- General markup improvements.
  - Removed mention of creating a voting account as it has been deprecated.
  - Instructions were further clarified and updated to strongly recommend the
    use of hcGUI/Paymetheus.
  - Fragments of invalid markup were fixed.

## 1.1.1 Upgrade Guide

1) Announce maintenance and shut down hcstakepool.
2) Perform upgrades on each hcd+hcwallet+stakepoold voting cluster one at a
   time.
   * Stop stakepoold, hcwallet, and hcd.
   * Upgrade hcd, hcwallet to 1.1.0 release binaries or git. If compiling from
   source, Go 1.9 is recommended to pick up improvements to the Golang runtime.
   * Restart hcd, hcwallet.
   * Upgrade stakepoold.
   * Start stakepoold.
3) Upgrade and start hcstakepool.  If you are maintaining a fork, note that
   you need to update the hcd/chaincfg dependency to a revision that contains
   the new agenda.
4) hcstakepool will reset the votebits for all users to 1 when it detects the
   new vote version via stakepoold.
5) Announce maintenance complete after verifying functionality.  If possible,
   also announce that a new voting agenda is available and users must login
   to set their preferences for the new agenda.

## Requirements

- [Go](http://golang.org) 1.8.3 or newer.
- MySQL
- Nginx or other web server to proxy to hcstakepool

## Installation

#### Linux/BSD/MacOSX/POSIX - Build from Source

Building or updating from source requires the following build dependencies:

- **Go 1.8.3 or newer**

  Installation instructions can be found here: http://golang.org/doc/install.
  It is recommended to add `$GOPATH/bin` to your `PATH` at this point.

- **Dep**

  Dep is used to manage project dependencies and provide reproducible builds.
  To install:

  `go get -u github.com/golang/dep/cmd/dep`

Unfortunately, the use of `dep` prevents a handy tool such as `go get` from
automatically downloading, building, and installing the source in a single
command.  Instead, the latest project and dependency sources must be first
obtained manually with `git` and `dep`, and then `go` is used to build and
install the project.

- Run the following command to obtain the hcstakepool code and all dependencies:

```bash
$ git clone https://github.com/HcashOrg/hcstakepool $GOPATH/src/github.com/HcashOrg/hcstakepool
$ cd $GOPATH/src/github.com/HcashOrg/hcstakepool
$ dep ensure
```

- Assuming you have done the below configuration, build and run hcstakepool:

```bash
$ cd $GOPATH/src/github.com/HcashOrg/hcstakepool
$ go build
$ ./hcstakepool
```

- Build stakepoold and copy it to your voting nodes:

```bash
$ cd $GOPATH/src/github.com/HcashOrg/hcstakepool/backend/stakepoold
$ go build
```

## Updating

To update an existing source tree, pull the latest changes and install the
matching dependencies:

```bash
$ cd $GOPATH/src/github.com/HcashOrg/hcstakepool
$ git pull
$ dep ensure
$ go build
$ cd $GOPATH/src/github.com/HcashOrg/hcstakepool/backend/stakepoold
$ go build
```

## Setup

#### Pre-requisites

These instructions assume you are familiar with hcd/hcwallet.

- Create basic hcd/hcwallet/hcctl config files with usernames, passwords, rpclisten, and network set appropriately within them or run example commands with additional flags as necessary

- Build/install hcd and hcwallet from latest master

- Run hcd instances and let them fully sync

#### Stake pool fees/cold wallet

- Setup a new wallet for receiving payment for stake pool fees.  **This should be completely separate from the stake pool infrastructure.**

```bash
$ hcwallet --create
$ hcwallet
```

- Get the master pubkey for the account you wish to use. This will be needed to configure hcwallet and hcstakepool.

```bash
$ hcctl --wallet getmasterpubkey
```

- Mark 10000 addresses in use for the account so the wallet will recognize transactions to those addresses. Fees from UserId 1 will go to address 1, UserId 2 to address 2, and so on.

```bash
$ hcctl --wallet accountsyncaddressindex default 0 10000
```

#### Stake pool voting wallets

- Create the wallets.  All wallets should have the same seed.  **Backup the seed for disaster recovery!**

```bash
$ hcwallet --create
```

- Start a properly configured hcwallet and unlock it. See sample-hcwallet.conf.

```bash
$ hcwallet
```

- Get the master pubkey from the default account.  This will be used for votingwalletextpub in hcstakepool.conf.

```bash
$ hcctl --wallet getmasterpubkey default
```

#### MySQL

- Install, configure, and start MySQL

- Add stakepool user and create the stakepool database

```bash
$ mysql -uroot -ppassword

MySQL> CREATE USER 'stakepool'@'localhost' IDENTIFIED BY 'password';
MySQL> GRANT ALL PRIVILEGES ON *.* TO 'stakepool'@'localhost' WITH GRANT OPTION;
MySQL> FLUSH PRIVILEGES;
MySQL> CREATE DATABASE stakepool;
```

#### Nginx/web server

- Adapt sample-nginx.conf or setup a different web server in a proxy configuration

#### stakepoold
- Adapt sample-stakepoold.conf and run stakepoold.

#### hcstakepool

- Create the .hcstakepool directory and copy hcwallet certs to it
```bash
$ mkdir ~/.hcstakepool
$ cd ~/.hcstakepool
$ scp walletserver1:~/.hcwallet/rpc.cert wallet1.cert
$ scp walletserver2:~/.hcwallet/rpc.cert wallet2.cert
$ scp walletserver1:~/.stakepoold/rpc.cert stakepoold1.cert
$ scp walletserver2:~/.stakepoold/rpc.cert stakepoold2.cert
```

- Copy sample config and edit appropriately
```bash
$ cp -p sample-hcstakepool.conf hcstakepool.conf
```

## Running

The easiest way to run the stakepool code is to run it directly from the root of
the source tree:

```bash
$ cd $GOPATH/src/github.com/HcashOrg/hcstakepool
$ go build
$ ./hcstakepool
```

If you wish to run hcstakepool from a different directory you will need to change **publicpath** and **templatepath**
from their relative paths to an absolute path.

## Development

If you are modifying templates, sending the USR1 signal to the hcstakepool process will trigger a template reload.

## Operations

- hcstakepool will connect to the database or error out if it cannot do so

- hcstakepool will create the stakepool.Users table automatically if it doesn't exist

- hcstakepool attempts to connect to all of the wallet servers on startup or error out if it cannot do so

- hcstakepool takes a user's pubkey, validates it, calls getnewaddress on all the wallet servers, then createmultisig, and finally importscript.  If any of these RPCs fail or returns inconsistent results, the RPC client built-in to hcstakepool will shut down and will not operate until it has been restarted.  Wallets should be verified to be in sync before restarting.

- User API Tokens have an issuer field set to baseURL from the configuration file.
  Changing the baseURL requires all API Tokens to be re-generated.

## Adding Invalid Tickets

#### For Newer versions / git tip

If a user pays an incorrect fee, login as an account that meets the
adminUserIps and adminUserIds restrictions and click the 'Add Low Fee Tickets'
link in the menu.  You will be presented with a list of tickets that are
suitable for adding.  Check the appropriate one(s) and click the submit button.
Upon success, you should see the stakepoold logs reflect that the new tickets
were processed.

#### For v1.1.1 and below

If a user pays an incorrect fee you may add their tickets like so (requires hcd running with txindex=1):

```bash
hcctl --wallet stakepooluserinfo "MultiSigAddress" | grep -Pzo '(?<="invalid": \[)[^\]]*' | tr -d , | xargs -Itickethash hcctl --wallet getrawtransaction tickethash | xargs -Itickethex hcctl --wallet addticket "tickethex"
```

## Backups, monitoring, security considerations

- MySQL should be backed up often and regularly (probably at least hourly). Backups should be transferred off-site.  If using binary backups, do a test restore. For .sql files, verify visually.

- A monitoring system with alerting should be pointed at hcstakepool and tested/verified to be operating properly.  There is a hidden /status page which throws 500 if the RPC client is shutdown.  If your monitoring system supports it, add additional points of verification such as: checking that the /stats page loads and has expected information in it, create a test account and setup automated login testing, etc.

- Wallets should never be used for anything else (they should always have a balance of 0)

## Disaster Recovery

**Always keep at least one wallet voting while performing maintenance / restoration!**

- In the case of a total failure of a wallet server:
  * Restore the failed wallet(s) from seed
  * Restart the hcstakepool process to allow automatic syncing to occur.

## IRC

- irc.freenode.net
- channel #HcashOrg

## Issue Tracker

The [integrated github issue tracker](https://github.com/HcashOrg/hcstakepool/issues)
is used for this project.

## License

hcstakepool is licensed under the [copyfree](http://copyfree.org) MIT/X11 and
ISC Licenses.

## Version History
- 1.1.0 - Architecture change.
  * Per-ticket votebits were removed in favor of per-user voting preferences.
    A voting page was added and the API upgraded to v2 to support getting and
    setting user voting preferences.
  * Addresses from the wallet servers which are needed for generating the 1-of-2
    multisig ticket address are now derived from the new votingwalletextpub
    config option. This removes the need to call getnewaddress on each wallet.
  * An experimental daemon (stakepoold) that votes according to user preference
    is available for testing on testnet. This daemon is not for use on mainnet
    at this time.
- 1.0.0 - Major changes/improvements.
  * API is now at v1 status.  API Tokens are generated for all users with a
    verified email address when upgrading.  Tokens are generated for new
    users on demand when visiting the Settings page which displays their token.
    Authenticated users may use the API to submit a public key address and to
    retrieve ticket purchasing information.  The stake pool's stats are also
    available through the API without authentication.
- 0.0.4 - Major changes/improvements.
  * config.toml is no longer required as the options in that file have been
    migrated to hcstakepool.conf.
  * Automatic syncing of scripts, tickets, and vote bits is now performed at
    startup.  Syncing of vote bits is a long process and can be skipped with the
    SkipVoteBitsSync flag/configuration value.
  * Temporary wallet connectivity errors are now handled much more gracefully.
  * A preliminary v0.1 API was added.
- 0.0.3 - More expected/basic web application functionality added.
  * SMTPHost now defaults to an empty string so a stake pool can be used for
    development or testing purposes without a configured mail server.  The
    contents of the emails are sent through the logger so links can still be
    followed.
  * Upon sign up, users now have an email sent with a validation link.
    They will not be able to sign in until they verify.
  * New settings page that allows users to change their email address/password.
  * Bug fix to HeightRegistered migration for users who signed up but never
    submitted an address would not be able to login.
- 0.0.2 - Minor improvements/feature addition
  * The importscript RPC is now called with the current block height at the
    time of user registration. Previously, importscript triggered a rescan
    for transactions from the genesis block.  Since the user just registered,
    there won't be any transactions present.  A new HeightRegistered column
    is automatically added to the Users table.  A default value of 15346 is
    used for existing users who already had a multisigscript generated.
    This can be adjusted to a more reasonable value for you pool by running
    the following MySQL query:
    ```UPDATE Users SET HeightRegistered = NEWVALUE WHERE HeightRegistered = 15346;```
  * Users may now reset their password by specifying an email address and
    clicking a link that they will receive via email.  You will need to
    add a proper configuration for your mail server for it to work properly.
    The various SMTP options can be seen in **sample-hcstakepool.conf**.
  * User instructions on the address and ticket pages were updated.
  * SpentBy link added to the voted tickets display.
- 0.0.1 - Initial release for mainnet operations
