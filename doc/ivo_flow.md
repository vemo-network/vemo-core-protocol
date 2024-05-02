

@startuml
actor TokenHolder as "Token Holder"
entity VestingPoolFactory as "Vesting Pool Factory"
entity VestingPool as "Vesting Pool"
entity Collection as "NFT Collection"
entity VoucherFactory as "Voucher Factory"
entity VoucherAccount as "Voucher Account"
actor PoolParticipant as "Pool Participants"

TokenHolder -> VestingPoolFactory: Lock principle tokens\nwith vesting scheme
create VestingPool
VestingPoolFactory -> VestingPool: New Vesting Pool created

PoolParticipant -> VestingPool: Mint voucher\nwith desired exchange token
VestingPool -> VoucherFactory: Mint voucher\nwith vesting scheme and principle amount
VoucherFactory -> Collection: Request to DareNFT protocol to create collection
Collection -> PoolParticipant: Mint NFT that represents ownership of voucher
create VoucherAccount
VoucherFactory -> VoucherAccount: Create VoucherAccount linked to NFT

PoolParticipant -> VoucherAccount: Redeem tokens\nat proper vesting time
@enduml