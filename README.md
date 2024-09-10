## Vemo core-protocol
This repository contains the core smart contracts for the Vemo Protocol.

## Documentations
Refer https://docs.vemo.network/ for more information about our main products - Smart Voucher and Vemo Wallet

## Deployment contracts
Deployment Wallet on production ARB
| Contract Name | Address | Commit |
| --- | --- | --- |
| WalletFactory Proxy |  0x5A72A673f0621dC3b39B59084a72b95706E75EFd |
| guardian |  0xC833002b8179716Ae225B7a2B3DA463C47B14F76 |
| account v3 |   0xcb4a7FF79E90BDE163583f20BB96E8610b0b5829 |
| accountProxy | 0xE1E5F84F59BB5B55fAdec8b9496B70Ca0A312c73 |
| account registry | 0x000000006551c19487814612e58FE06813775758 |
|  collection deployer |  0xba56F3A85080c48Bbd9687A77b12c8fB00411dD2 |
| vemoCollection | 0xa815Fd40821b722765Daa326177E3832703C390f |
|  vePendle voter |  0xf9ad84fE8e4Cf9A521369650E29000F621dB7C90 |
|  vePendle voter | 0x094b8880C2F318f866Cf704cF5a89B541157407B |
|  term | 0xE5dfC61304fFC39f1B464dd3eF4FCc36679242c7 |
|  descriptor | 0x75aF44Cf66e63FaE6E27DF3B5F9b4AA57330F80B |

Deployment Wallet on ARB, BNB testnet
| Contract Name | Address | Commit |
| --- | --- | --- |
| collection | 0x8199F4C7A378B7CcCD6AF8c3bBcF0C68A353dAeB |
| guardian | 0xBE67034116BBc44f86b4429D48B1e1FB2BdAd9b7 |
| account v3 |  0x466a8D7e8ea7140ace60CD63d7D24199EE493238 |
| accountProxy | 0xF21e3FEde83E30Ab18fe7624C8c2b5DC7E4b0c18 |
| account registry | 0x000000006551c19487814612e58FE06813775758 |
| wallet factory proxy | 0xe2eBB6c62469f5afc0134DAbc9dD0e77F16eFba3 |
| walletfactory | 0xdd29355A71040C1122CfA60A6Dcf42c4C258EDc6 |
| layerzero OApp | 0x823b6CeA760716F40D6CA720a11f7459Fa361e9e |



Deployment voucher on Avax
Owner: 0xF42694796976e9Fc2fA7287b4CFAD218516d0BC7

| Contract Name | Address | Commit |
| --- | --- | --- |
| Factory | 0x34A4ac15dcAA1f498ca405a4d6C3aEc8108600b8 |  |
| Data Registry V2 | 0x6dc54cd9570F30b28fDa3d82FA6191136Ef8d082 |  |
| VoucherFactory | 0xbB740E17f3c177172CaAcCef2F472DB41b9b1d19 |  |
| VoucherFactory Imp | 0x90372156b0a3e456806cFD37D431B6c2f1e65448 |  |
| AccountRegistry | 0x21672f86E2a77b7725169d09750dBC9D1E4b27b2 |  |
| VoucherAccount Iml | 0xC93a091b5fd9A4c0A310507a696Dd51AFA2Dd81E |  |
| Vemo Vesting Factory | 0x296d2C371D4Be8A5368f5E541Bc62926051E92CC | |
| Vemo Vesting Factory Impl | 0xbF907b4ff56E6EF9E648B4831aBF526cF5494896 | |

-----------------------------------
Deployment voucher on bnb mainnet 
| Contract Name | Address | Commit |
| --- | --- | --- |
| Factory | 0x75fc4ABf45d38176544833164e4E870B1A5E3103 |  |
| Data Registry V2 | 0xa64001F7943792372C5B777e49f3B1d0A43282Fc |  |
| VoucherFactory | 0x9869524fd160fe3adDA6218883B6526c0977D3a5 |  |
| VoucherFactory Imp | 0xfb62695F550929b6630D7A395D8aB69605DbE230 |  |
| AccountRegistry | 0x4D5d103178846F14DC0beeD943d5d83F0F706F35 |  |
| VoucherAccount Iml | 0xA70e9ECC8013a6B40BbBD03a6dC60d0390ACA0A3 |  |
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

- Wallet contracts

-------------------------------------------------------
Deployment voucher on avax testnet 
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
| Vemo Wallet Factory Proxy | 0xAb3a6F5c42FF0efD402a8cd7EcEa18F8759AEE73|
| Account Guardian |  0x52ab1c39132338A9af251f7e5c047b435Db51A11|
| Account Wallet Proxy |  0x69a1A5Dc5dB3b4a0Fdd2d92658C1A6264599761f |
| Account Wallet V3  | 0x2243357994CE659d96ECeF8b26d1F6215e0052d9|
| WalletFactory Proxy | 0xAb3a6F5c42FF0efD402a8cd7EcEa18F8759AEE73|
| NFT Descriptor | 0x6ca9bb43548FfE3b2ABE0ca6A9Ba6C5C60bba463|
-------------------------------------------------------
Deployment voucher on bnb testnet
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
| Guardian | 0xb50D9B55b3F994ce5F881c4FAeA374cF69dBA3b1 |
| Wallet impl |  0x1146212217dBC5A3ee7954D55A194c232F4aDeAC  |
| Wallet Proxy | 0xEA8909794F435ee03528cfA8CE8e0cCa8D7535Ae |
| ERC6551 registry |  0x0deC1D7E2789f80084bB0d516381Cf80B0E7c5f7 |
| WalletFactory Impl | 0xD629D25e20F26587C2Ee608fA0ebCA3aD4d00c6D |
| WalletFactory | 0xbd29f427d04Df4c89c5c5616e866c365a6Bf3682 |
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

forge verify-contract 0x1eE14D9E455B43449F870A9668889E77A5c36c91  --watch --chain 56  src/accounts/AccountV3.sol:AccountV3  --etherscan-api-key "1VYRT81XHNBY8BC2X88N9ZF4XRBXUJDYKQ"  --num-of-optimizations 200 --compiler-version 0.8.23 --constructor-args `cast abi-encode "constructor(address,address,address,address)" 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789 0xcA11bde05977b3631167028862bE2a173976CA11 0x0deC1D7E2789f80084bB0d516381Cf80B0E7c5f7 0xb50D9B55b3F994ce5F881c4FAeA374cF69dBA3b1`


