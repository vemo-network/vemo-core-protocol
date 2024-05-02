@startuml
actor TokenHolder as "Token Holder"
entity VoucherFactory as "Voucher Factory"
entity VoucherAccount as "Voucher Account"
entity Collection as "NFT Collection"

TokenHolder -> VoucherFactory: Request/Create voucher collection
create Collection
VoucherFactory -> Collection: Mint a nft collection


TokenHolder -> VoucherFactory:  Lock principle tokens\nwith vesting scheme
create Collection
VoucherFactory -> Collection: mint voucher nft
Collection -> TokenHolder: NFT minted
create VoucherAccount
VoucherFactory -> VoucherAccount: mint voucher account
VoucherAccount -> TokenHolder: voucher account minted



TokenHolder -> VoucherAccount: Redeem tokens\nat proper vesting time
@enduml