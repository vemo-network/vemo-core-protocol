## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge clean && forge build && forge test --ffi -vvvv
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot --gas-report
```


### Deploy

```shell
 forge clean && forge build && forge script script/Deploy.s.sol  --rpc-url https://api.avax-test.network/ext/C/rpc --private-key   --broadcast
```

### Cast

```shell
$ cast <subcommand>
```

### Verify contract

```shell
forge verify-contract "contract-name" --watch --chain 56 "contract_path:contract_name"  --etherscan-api-key "" --num-of-optimizations 200 --compiler-version 0.8.21 --constructor-args "contract-arg"

Note
1. there are some scan/explorers that don't accept the tx parameters as contruction-arg, there is a script call abi.encode.js support encode/decode manually.
2. 0.8.21 is the version that work for verify contract.

3. 1967proxy contructor args (bscscan sometimes can't regconize the proxy)
0000000000000000000000000f3a3ba0f9d0f48a38c48188eddcf5f196a56854000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a41459457a000000000000000000000000540e56fb440f71b788c8fee2aab5a2ce292d65fc00000000000000000000000075fc4abf45d38176544833164e4e870b1a5e3103000000000000000000000000a64001f7943792372c5b777e49f3b1d0a43282fc0000000000000000000000004d5d103178846f14dc0beed943d5d83f0f706f35000000000000000000000000eb9833ef02c9502436bce90b55ddb9afcaf1aa9900000000000000000000000000000000000000000000000000000000

