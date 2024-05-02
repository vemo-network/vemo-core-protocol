@startuml
skinparam sequenceMessageAlign center
actor TokenHolder as "Token Holder"
entity VoucherFactory as "Voucher Factory"
entity VoucherAccount as "Voucher Account"
entity NFT as "NFT Collection"


TokenHolder -> VoucherFactory:  (1) Create Voucher
create NFT
VoucherFactory -> NFT: (2) mint voucher's nft
NFT -> TokenHolder: (3) new NFT
create VoucherAccount
VoucherFactory -> VoucherAccount: (4) create an associated voucher account 


@enduml