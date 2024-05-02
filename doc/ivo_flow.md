

@startuml
skinparam sequenceMessageAlign center
actor PoolParticipant as "Pool Participants"
entity VestingPool as "Vesting Pool"
entity Collection as "NFT Collection"
entity VoucherFactory as "Voucher Factory"
entity VoucherAccount as "Voucher Account"


PoolParticipant -> VestingPool: (1) Mint voucher\nwith desired exchange token
VestingPool -> VoucherFactory: (2) Mint voucher
VoucherFactory -> Collection: (3) Mint NFT
Collection -> PoolParticipant: (4) Send NFT
create VoucherAccount
VoucherFactory -> VoucherAccount: (5) Create associated VoucherAccount

@enduml