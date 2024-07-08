Vemo is a DeFi protocol designed to tokenize locked positions into dynamic assets, enabling tradability. We offer several product lines:
* Smart Vouchers: These assets have built-in release schedules. Smart voucher holders can claim their tokens according to the preset release schedule without requiring external authorization. The voucher market operates independently from the spot market, ensuring that trading vouchers does not affect the spot price of the underlying token. This innovative approach fosters a decentralized ecosystem where locked positions are seamlessly transformed into tradable assets.
* Smart Wallet: Users can farm points and store veToken-like, untransferable tokens. This feature enables a new type of asset and market for points, veTokens, launchpad allocations, and any other locked assets you can imagine. These assets can then be traded, expanding the utility and liquidity of otherwise non-transferable tokens.
* Vemo Market: Where Smart Wallets and Smart Vouchers can be traded.

### Overview
Smart Voucher overview
![smart-voucher-overview.png](https://i.postimg.cc/Bnvzm00m/Untitled-Diagram-drawio-8.png)

Vemo Wallet overview
![vemo-wallet-overview.png](https://i.postimg.cc/RVR1Byck/Untitled-Diagram-drawio-7.png)

When a launchpad user purchases an allocation (e.g., $5000 token sale X), they must wait for the TGE (Token Generation Event) or follow a vesting schedule to receive the actual tokens they can sell or exchange. During this waiting period, users cannot liquidate their allocation. Vemo offers launchpads a convenient solution, allowing them to assist their users by integrating in one of two ways:

#### Smart Wallet
1. After purchasing an allocation, the user will receive a Smart Wallet containing the allocation.
2. The user can trade the Smart Wallet on any ERC721 marketplace (e.g., OpenSea, Rarible), especially the Smart market, which is optimized for Smart Wallet information.
3. The user can log in to the launchpad using the Smart Wallet (via WalletConnect) to claim their vested tokens if they still want to participate in any launchpad utilities.

#### Smart Voucher
1. After purchasing an allocation, the user will receive a Smart Voucher containing the vesting schedule and locked tokens.
2. The user's journey will remain the same.
3. The user can trade the Smart Voucher on the Vemo market.

The below documentation contains the materials for interating with Smart Wallet
#### Integrate Smart Wallet Flow
![vemo-wallet-overview.png](https://www.planttext.com/api/plantuml/png/TP6zJiD048JxVOgLArnG13051OfZaOeWH2AeL-jLSk9yP-wdoDkpTg8OAw8xpNmpiz8jOwAGScSXVXlNKw0Ee_naSImRYP7sKbkpTyZYaWGWJZxWksOCcvvSYaWHYrVAZWyzjJEh00sPTCJ9di4N_rCw_qNMIbgF0yUH6rGyoNZM2m2OZTy-J-LFUBCeSPKrRQrdIiOxcAOLlThHo5s9JH1AWjjEcy-3S7sIvXkl0W-z6hmlSMDSmhVr3YPZmFvUgE13YLjnxGZoQUhbetcigaNDxBFxPspEQ4zrkPHYz6pqrU9kLGCijLx_y1S0)

The deployment contract addresses of Wallet Factory on different chains: 
| Contract Name | Address |
| --- | --- |
| Avax Testnet | 0xAb3a6F5c42FF0efD402a8cd7EcEa18F8759AEE73 |
| BNB Testnet | 0xbd29f427d04Df4c89c5c5616e866c365a6Bf3682 |

### Interface
- **WalletFactory.createWalletCollection**: When launchpad runs a new campaign, they use Vemo's UI to create a new NFT collection first.
```
function createWalletCollection(
        uint160 collectionIndex,
        string calldata name,
        string calldata symbol,
        string calldata dappURI 
    ) external returns (address) {}
```
- **WalletFactory.createFor**: Create a wallet (NFT and associated ERC6551 Account) for a specific user
```
function createFor(address nftAddress, string memory tokenUri, address receiver) external  returns (uint256, address) {
```

### Events
- **CollectionCreated**: Emitted when a NFT collection is created.
```
event CollectionCreated(
    address indexed collection,
    uint256 indexed collectionIndex,
    string  name,
    string  symbol,
    string  dappURI
);
```
- **WalletCreated**: Emitted when a wallet is created.
```
event WalletCreated(
    address indexed account,
    address indexed nftCollection,
    uint256 tokenId,
    address receiver
);
```


