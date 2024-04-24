// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Create2.sol";

import "./interfaces/IERC6551Registry.sol";

contract ERC6551Registry is IERC6551Registry {
    function getERC6551CreationCode(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        bytes32 salt
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73", // ERC-1167 constructor + header
            implementation,
            hex"5af43d82803e903d91602b57fd5bf3", // ERC-1167 footer
            abi.encode(uint256(salt), chainId, tokenContract, tokenId)
        );
    }

    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        bytes calldata initData
    ) external returns (address) {
        bytes memory code = getERC6551CreationCode(implementation, chainId, tokenContract, tokenId, salt);

        address _account = Create2.computeAddress(bytes32(salt), keccak256(code));

        if (_account.code.length != 0) return _account;

        emit ERC6551AccountCreated(_account, implementation, salt, chainId, tokenContract, tokenId);

        _account = Create2.deploy(0, salt, code);

        if (initData.length != 0) {
            (bool success,) = _account.call(initData);
            if (!success) revert ERC6551AccountCreationFailed();
        }

        return _account;
    }

    function account(address implementation, bytes32 salt, uint256 chainId, address tokenContract, uint256 tokenId)
        external
        view
        returns (address)
    {
        bytes32 bytecodeHash = keccak256(getERC6551CreationCode(implementation, chainId, tokenContract, tokenId, salt));

        return Create2.computeAddress(bytes32(salt), bytecodeHash);
    }
}
