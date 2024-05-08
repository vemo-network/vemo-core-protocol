

@startuml
skinparam sequenceMessageAlign center
actor PoolParticipant as "Pool Participants"
entity Voucher as "Voucher"
entity ERC6551Account as "ERC6551Account"


PoolParticipant -> Voucher: (1) Redeem
Voucher -> ERC6551Account: (2) Redeem
ERC6551Account -> PoolParticipant: (3) principle tokens
@enduml