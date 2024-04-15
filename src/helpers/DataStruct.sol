// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum FreeMintableKind {
  NON_FREE_MINTABLE,
  FREE_MINT_COMMUNITY,
  FREE_MINT_WHITELIST
}

enum CollectionKind {
  ERC721Standard, 
  ERC721A
}

struct CollectionSettings {
  uint96 royaltyRate;
  bool isSoulBound;
  FreeMintableKind isFreeMintable;
  bool isSemiTransferable;
}

struct RoyaltySettings {
  address receiver;
  uint96 rate;
}

struct TokenRange {
  uint256 start;
  uint256 end;
}

struct DataRegistrySettings {
  bool disableComposable;
  bool disableDerivable;
}

