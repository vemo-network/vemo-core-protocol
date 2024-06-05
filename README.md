## Vemo core-protocol
Vemo is a DeFi protocol designed to tokenize locked positions into dynamic NFTs with on-chain balances and built-in release schedules, known as smart vouchers. Smart voucher holders enjoy the freedom to claim their tokens according to the preset release schedule, all without requiring external authorization. Remarkably, the voucher market operates autonomously from the spot market, ensuring that trading vouchers has no impact on the spot price of the underlying token. This innovative approach fosters a decentralized ecosystem where locked positions are seamlessly transformed into tradable assets. This unlocks new possibilities for liquidity provision and financial flexibility in order to revolutionize the DeFi landscape to the next level.  

The core framework of Vemo in version 1 revolves around three key contracts: VoucherFactory.sol, VoucherAccount.sol and AccountRegistry.sol
* VoucherFactory Contract: This contract functions as the manager for both the NFT collection and the associated token-bound accounts. It empowers users to create voucher collections and acts as a gateway for creating VoucherAccount.
* VoucherAccount Contract: This contract is responsible for holding the token assets. Each (token-bound account) maintains a one-to-one linkage with an ERC721 token (NFT). The contract utilizes mechanisms that allow for claiming rewards over a fixed period or on a linear schedule (hours, days, or months). This implementation enables the trading of vesting positions through ERC721 ownership while upholding the vesting logic.
* AccountRegistry Contract: functions as a factory for ERC6551Account. This contract allows for the creation and retrieval of token-bound accounts for non-fungible tokens (NFTs) using the CREATE2 opcode. This contract serves as a registry for token-bound accounts associated with NFTs, providing functionalities for their deterministic creation and retrieval.

Moreover, Vemo is designed with scalability in mind. It can accommodate locked positions from diverse sources, such as staking as well as possess the flexibility to adapt to various business logics, with the potential for future expansion planned in version 2.

## Documentation
Deployment on Avax
Owner: 0xF42694796976e9Fc2fA7287b4CFAD218516d0BC7

| Contract Name | Address | Commit |
| --- | --- | --- |
| Factory | 0x34A4ac15dcAA1f498ca405a4d6C3aEc8108600b8 |  |
| Data Registry V2 | 0x6dc54cd9570F30b28fDa3d82FA6191136Ef8d082 |  |
| VoucherFactory | 0xbB740E17f3c177172CaAcCef2F472DB41b9b1d19 | Push production code	560342a	Matthew Dinh mailto:tiendv.52@gmail.com	Apr 13, 2024 at 11:52 AM |
| VoucherFactory Imp | 0xa1bc57835A7FC612e3b2E36a6D44D3cE8EC3fed2 | Push production code	560342a	Matthew Dinh mailto:tiendv.52@gmail.com	Apr 13, 2024 at 11:52 AM |
| AccountRegistry | 0x21672f86E2a77b7725169d09750dBC9D1E4b27b2 | Push production code	560342a	Matthew Dinh mailto:tiendv.52@gmail.com	Apr 13, 2024 at 11:52 AM |
| VoucherAccount Iml | 0xEEa72E7B0aF76DA1Fb728FB7B3c4cC40184a66c0 | Push production code	560342a	Matthew Dinh mailto:tiendv.52@gmail.com	Apr 13, 2024 at 11:52 AM |
| Vemo Vesting Factory | 0x296d2C371D4Be8A5368f5E541Bc62926051E92CC | Prepare for Production	35996fa	Matthew Dinh mailto:tiendv.52@gmail.com	Apr 8, 2024 at 11:24 PM |
| Vemo Vesting Factory Impl | 0xbF907b4ff56E6EF9E648B4831aBF526cF5494896 | Prepare for Production	35996fa	Matthew Dinh mailto:tiendv.52@gmail.com	Apr 8, 2024 at 11:24 PM |

-----------------------------------
Deployment on bnb mainnet 
| Contract Name | Address | Commit |
| --- | --- | --- |
| Factory | 0x75fc4ABf45d38176544833164e4E870B1A5E3103 |  |
| Data Registry V2 | 0xa64001F7943792372C5B777e49f3B1d0A43282Fc |  |
| VoucherFactory | 0x9869524fd160fe3adDA6218883B6526c0977D3a5 |  |
| VoucherFactory Imp | 0x0F3A3BA0f9D0f48A38c48188EDDCF5F196a56854 |  |
| AccountRegistry | 0x4D5d103178846F14DC0beeD943d5d83F0F706F35 |  |
| VoucherAccount Iml | 0xEb9833eF02c9502436bCe90b55DDB9AFcaF1AA99 |  |
| Vemo Vesting Factory | 0x29f118a2Eb3c7754847a104ABeDF7776Ee5D4C80 |  |
| Vemo Vesting Factory Impl | 0x79CC5d5Fb0E876C9A81FC5b47B2E978D0Bb33c94 |  |

MULTISIG OWNER: `0x540e56Fb440f71b788c8Fee2aab5A2ce292D65fC`

- After deploy Voucher Contract:
    - Set `Factory` and `DataRegistry` for VoucherFactory if needed
    - Set `DEFAULT_ADMIN_ROLE` (0x0000000000000000000000000000000000000000000000000000000000000000) and `WRITER_ROLE` (0x2b8f168f361ac1393a163ed4adfa899a87be7b7c71645167bdaddd822ae453c8) for VoucherFactory in DataRegistry
    - If Collection already existed:
        - set `MINTER_ROLE` (0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6) for VoucherFactory in Collection
        - call `setX()` of VoucherFactory contract to set token - collection map
    - If Collection does not exist:
        - call `createVoucherCollection()` of VoucherFactory to create collection
- After deploy Vemo Vesting Pool
    - Set Voucher contract above

-------------------------------------------------------
Deployment on avax testnet 
owner: 0xaA6Fb5C8C0978532AaA46f99592cB0b71F11d94E

```
address owner -->  0x581530Bb07091Fe1f285211C24BA43Da0F005FC9
        address factoryAddress,
        address dataRegistry,
        address erc6551Registry,
        address erc6551AccountImpl
```

| Contract Name | Address |
| --- | --- |
| Factory |  |
| Data Registry V2 |  |
| Voucher Factory Proxy | 0x65B903D7903d277bE600B8524a759aBEa3CC7e1A |
| VoucherFactory Imp | 0x8b8950E6efb667895B60827c6c121358A02B77FD |
| AccountRegistry |  |
| VoucherAccount Iml | 0xd987d549d726cc07006584606f030118e900297B |
| Vemo Vesting Factory | 0x5ef5D34bcbCefdFa6442aD7672a4147A98C08698 |
| Vemo Vesting Factory Impl |  |


-------------------------------------------------------
Deployment on bnb testnet
| Contract Name | Address |
| --- | --- |
| Factory | 0x702067e6010E48f0eEf11c1E06f06aaDb04734e2 |
| Data Registry V2 | 0xc27570A03FCd38CeD53c23df0948072aC58F41B6 |
| VoucherFactory | 0xD0901C6fE9FA1A8D56D2250Db272D65391117dfc |
| VoucherFactory Imp | 0xA2a89a309bb061a7ab4B21D4F99545701C57E994 |
| AccountRegistry | 0x429419cdedF706b4e8303a65a6c4a539fdC0e0D3 |
| VoucherAccount Iml | 0x8C5a1809C962cb1bc664C7395F1C48E0f69d3f9F |
| Vemo Vesting Factory | 0x38BE5E3f75C7D5F67558FC47c75c010783a28Cc9 |
| Vemo Vesting Factory Impl | 0x21b2E6c9805871743aeAD44c65bAb6cb9F0f1c60 |

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
forge verify-contract "contract-address" --watch --chain 56 "contract_path:contract_name"  --etherscan-api-key "" --num-of-optimizations 200 --compiler-version 0.8.21 --constructor-args "contract-arg"

Note
1. there are some scan/explorers that don't accept the tx parameters as contruction-arg, there is a script call abi.encode.js support encode/decode manually.
2. 0.8.21 is the version that work for verify contract.

3. 1967proxy contructor args (bscscan sometimes can't regconize the proxy)
0000000000000000000000000f3a3ba0f9d0f48a38c48188eddcf5f196a56854000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a41459457a000000000000000000000000540e56fb440f71b788c8fee2aab5a2ce292d65fc00000000000000000000000075fc4abf45d38176544833164e4e870b1a5e3103000000000000000000000000a64001f7943792372c5b777e49f3b1d0a43282fc0000000000000000000000004d5d103178846f14dc0beed943d5d83f0f706f35000000000000000000000000eb9833ef02c9502436bce90b55ddb9afcaf1aa9900000000000000000000000000000000000000000000000000000000

