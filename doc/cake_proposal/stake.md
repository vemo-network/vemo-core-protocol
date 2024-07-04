@startuml
actor User
participant Vemo
participant "Token Bound Account" as TBA 
participant CakeProtocol


User -> Vemo : (1) send Cake
Vemo -> User : (2) send an NFT reprenting the stake
Vemo -> TBA : (3) create associated TBA
Vemo -> TBA : (4) transfer Cake to TBA
TBA  -> CakeProtocol: (5) stake Cake
CakeProtocol -> TBA : (6) send veCake



@enduml