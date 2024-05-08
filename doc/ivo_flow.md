

@startuml
skinparam sequenceMessageAlign center
actor PoolParticipant as "Pool Participants"
entity VestingPool as "Vesting Pool"
entity Collection as "NFT Collection"
entity Voucher as "Voucher"
entity ERC6551Account as "ERC6551Account"


PoolParticipant -> VestingPool: (1) Mint voucher\nwith desired exchange token
VestingPool -> Voucher: (2) Mint voucher
Voucher -> Collection: (3) Mint NFT
Collection -> PoolParticipant: (4) Send NFT
create ERC6551Account
Voucher -> ERC6551Account: (5) Create associated VoucherAccount

@enduml