
@startuml
actor TokenHolder as "Token Holder"
entity VestingPoolFactory as "Vesting Pool Factory"
entity VestingPool as "Vesting Pool"

TokenHolder -> VestingPoolFactory: Lock principle tokens\nwith vesting scheme
create VestingPool
VestingPoolFactory -> VestingPool: Create a vesting pool, lock the principle token

@enduml