// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/StdAssertions.sol";
import "forge-std/console.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "./WalletFactory.base.sol";

contract WalletFactoryUtilsTest is Test, WalletFactoryBaseTest {
    address randomAdrr = vm.addr(99999);
    address randomToken = vm.addr(99999);
    
    function testSetWalletCollection() public {
        vm.startPrank(user);
        vm.expectRevert();
        walletFactory.setWalletCollection(uint160(address(usdc)), randomAdrr);
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        walletFactory.setWalletCollection(uint160(address(usdc)), randomAdrr);
        vm.stopPrank();

        assertEq(walletFactory.walletCollections(uint160(address(usdc))), randomAdrr);
    }

    function testCreateWalletCollection() public {
        vm.startPrank(randomAdrr);
        vm.expectRevert();
        address nft = walletFactory.createWalletCollection(
            uint160(randomToken),
            "random",
            "random",
            address(vemoCollectionDescriptor)
        );
        vm.stopPrank();

        // could not create same nft with same person
        vm.startPrank(defaultAdmin);
        address _nft = walletFactory.createWalletCollection(
            uint160(randomToken),
            "random",
            "random",
            address(vemoCollectionDescriptor)
        );
        walletFactory.create(_nft, "");

        
        string memory description = ERC721(_nft).tokenURI(0);
        assertEq(
            _contains("data:application/json;base64,eyJuYW1lIjoicmFuZG9tICMwIiwgImRlc2NyaXB0aW9uIjoiVGhpcyBORlQgc2lnbmlmaWVzIHRoZSBvd25lcnNoaXAgb2YgYW4gYWNjb3VudCBjb250YWluaW5nIGNyeXB0byBhc3NldHMgb3Igb2ZmLWNoYWluIHBvaW50cywga25vd24gYXMgYSBWZW1vIE5GVCBBY2NvdW50IGZvbGxvd2luZyB0aGUgRVJDLTY1NTEgc3RhbmRhcmQuIE9ubHkgTkZUIGhvbGRlciBoYXMgY29tcGxldGUgY29udHJvbCBvdmVyIHRoZSBhc3NldHMgaW4gdGhlIGFjY291bnQuIEFkZGl0aW9uYWxseSwgdGhleSBjYW4gdHJhbnNmZXIgdGhlIGFjY291bnQgdG8gb3RoZXJzIGJ5IHRyYW5zZmVycmluZyBvciBzZWxsaW5nIE5GVCBvbiB0aGUgc2Vjb25kYXJ5IG1hcmtldC5cblxuIFZlbW8gQWNjb3VudCBhZGRyZXNzIGxpbmtlZCB0byB0aGlzIE5GVDogMHg2MDIyZTc2ZWZkM2ZlYjBlMThkMDc4YWQ4MmQ5MzhhZjY2ZTQ2Y2IzXG5cbkZvciBtb3JlIGRldGFpbHMsIHBsZWFzZSB2aXNpdCBodHRwczovL3ZlbW8ubmV0d29yay9cblxu4pqg77iPIERJU0NMQUlNRVI6IEl0IGlzIGhpZ2hseSByZWNvbW1lbmRlZCB0byB2ZXJpZnkgdGhlIGFzc2V0cyBpbiB0aGUgTkZUIEFjY291bnQgb24gVmVtbyBOZXR3b3JrIHdlYnNpdGUgYmVmb3JlIG1ha2luZyBhbnkgZGVjaXNpb25zLiIsICJpbWFnZSI6ICJkYXRhOmltYWdlL3N2Zyt4bWw7YmFzZTY0LFBITjJaeUIzYVdSMGFEMGlOVEF3SWlCb1pXbG5hSFE5SWpVd01DSWdkbWxsZDBKdmVEMGlNQ0F3SURVd01DQTFNREFpSUdacGJHdzlJbTV2Ym1VaUlIaHRiRzV6UFNKb2RIUndPaTh2ZDNkM0xuY3pMbTl5Wnk4eU1EQXdMM04yWnlJZ2VHMXNibk02ZUd4cGJtczlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5MekU1T1RrdmVHeHBibXNpUGp4eVpXTjBJSGRwWkhSb1BTSTFNREFpSUdobGFXZG9kRDBpTlRBd0lpQnllRDBpTWpRaUlHWnBiR3c5SWlNek9UUkZPRFlpTHo0OFp5QnpkSGxzWlQwaWJXbDRMV0pzWlc1a0xXMXZaR1U2YzJOeVpXVnVJajQ4Y21WamRDQjNhV1IwYUQwaU5UQXdJaUJvWldsbmFIUTlJalF5TVNJZ1ptbHNiRDBpZFhKc0tDTndZWFIwWlhKdU1GODVOekEzWHpVeU1UVTJLU0l2UGp3dlp6NDhjR0YwYUNCa1BTSk5NQ0F4TnpCSU1UTTJRekUwT1M0eU5UVWdNVGN3SURFMk1DQXhPREF1TnpRMUlERTJNQ0F4T1RSV016QTJRekUyTUNBek1Ua3VNalUxSURFME9TNHlOVFVnTXpNd0lERXpOaUF6TXpCSU1GWXhOekJhSWlCbWFXeHNQU0ozYUdsMFpTSWdabWxzYkMxdmNHRmphWFI1UFNJd0xqRWlMejQ4ZEdWNGRDQm1hV3hzUFNKM2FHbDBaU0lnWm1sc2JDMXZjR0ZqYVhSNVBTSXdMalVpSUhodGJEcHpjR0ZqWlQwaWNISmxjMlZ5ZG1VaUlITjBlV3hsUFNKM2FHbDBaUzF6Y0dGalpUb2djSEpsSWlCbWIyNTBMV1poYldsc2VUMGlWWEppWVc1cGMzUWlJR1p2Ym5RdGMybDZaVDBpTWpBaUlHWnZiblF0ZDJWcFoyaDBQU0kxTURBaUlHeGxkSFJsY2kxemNHRmphVzVuUFNJd0xqWmxiU0krUEhSemNHRnVJSGc5SWpVMklpQjVQU0kwTWpnaVBsQlBWMFZTUlVRZ1Fsa2dWa1ZOVHp3dmRITndZVzQrUEM5MFpYaDBQangwWlhoMElHWnBiR3c5SW5kb2FYUmxJaUI0Yld3NmMzQmhZMlU5SW5CeVpYTmxjblpsSWlCemRIbHNaVDBpZDJocGRHVXRjM0JoWTJVNklIQnlaU0lnWm05dWRDMW1ZVzFwYkhrOUlsVnlZbUZ1YVhOMElpQm1iMjUwTFhOcGVtVTlJakk0SWlCbWIyNTBMWGRsYVdkb2REMGlOVEF3SWlCc1pYUjBaWEl0YzNCaFkybHVaejBpTUdWdElqNDhkSE53WVc0Z2VEMGlNVGsySWlCNVBTSXlOamt1T0NJK1RrWlVJRUZqWTI5MWJuUThMM1J6Y0dGdVBqd3ZkR1Y0ZEQ0OGRHVjRkQ0JtYVd4c1BTSjNhR2wwWlNJZ2VHMXNPbk53WVdObFBTSndjbVZ6WlhKMlpTSWdjM1I1YkdVOUluZG9hWFJsTFhOd1lXTmxPaUJ3Y21VaUlHWnZiblF0Wm1GdGFXeDVQU0pWY21KaGJtbHpkQ0lnWm05dWRDMXphWHBsUFNJME9DSWdabTl1ZEMxM1pXbG5hSFE5SWpZd01DSWdiR1YwZEdWeUxYTndZV05wYm1jOUlqQmxiU0krUEhSemNHRnVJSGc5SWpFNU5pSWdlVDBpTWpFeUxqTWlQbFpsYlc4OEwzUnpjR0Z1UGp3dmRHVjRkRDQ4ZEdWNGRDQm1hV3hzUFNKM2FHbDBaU0lnZUcxc09uTndZV05sUFNKd2NtVnpaWEoyWlNJZ2MzUjViR1U5SW5kb2FYUmxMWE53WVdObE9pQndjbVVpSUdadmJuUXRabUZ0YVd4NVBTSlZjbUpoYm1semRDSWdabTl1ZEMxemFYcGxQU0l6TWlJZ1ptOXVkQzEzWldsbmFIUTlJalV3TUNJZ2JHVjBkR1Z5TFhOd1lXTnBibWM5SWpCbGJTSStQSFJ6Y0dGdUlIZzlJalUySWlCNVBTSTVPQzR5SWo0ak1Ed3ZkSE53WVc0K1BDOTBaWGgwUGp4MFpYaDBJR1pwYkd3OUluZG9hWFJsSWlCbWFXeHNMVzl3WVdOcGRIazlJakF1TmlJZ2VHMXNPbk53WVdObFBTSndjbVZ6WlhKMlpTSWdjM1I1YkdVOUluZG9hWFJsTFhOd1lXTmxPaUJ3Y21VaUlHWnZiblF0Wm1GdGFXeDVQU0pWY21KaGJtbHpkQ0lnWm05dWRDMXphWHBsUFNJeU9DSWdiR1YwZEdWeUxYTndZV05wYm1jOUlqQXVNRFZsYlNJK1BIUnpjR0Z1SUhnOUlqRTVOaUlnZVQwaU16RTNMamdpUGpCNE5qQXlMaTR1Tm1OaU16d3ZkSE53WVc0K1BDOTBaWGgwUGp4d1lYUm9JR1E5SWswNE9DNDJOakEzSURJM01pNDJNRFpNT0RBdU5USTFNeUF5T0RZdU9ETTBRemM1TGpZeE16Y2dNamc0TGpReU9TQTNOeTR5TnpZNElESTRPQzR6TnpjZ056WXVORE0zTmlBeU9EWXVOelEwVERZeExqRXpNVFFnTWpVMkxqazJORU0yTUM0Mk1EazVJREkxTlM0NU5Ea2dOakV1TnpNMk1pQXlOVFF1T0RneUlEWXlMamN6TmprZ01qVTFMalEwTWt3NE55NDNPRE01SURJMk9TNDBOelJET0RndU9EazVPQ0F5TnpBdU1EazVJRGc1TGpJNU1qTWdNamN4TGpVd01TQTRPQzQyTmpBM0lESTNNaTQyTURaYUlpQm1hV3hzUFNKM2FHbDBaU0l2UGp4d1lYUm9JR1E5SWsweE1ETXVPRFUySURJeE5DNHhOalJNTlRVdU56WTJOU0F5TXprdU5EUXpRelUwTGpBME1qSWdNalF3TGpNME9TQTFNUzQ1TURJMElESXpPUzQyTnpVZ05URXVNREkwT0NBeU16Y3VPVFE0VERRd0xqTTNOakVnTWpFMkxqazVOME16T1M0eU1URWdNakUwTGpjd05DQTBNQzQ0T1RNNElESXhNaUEwTXk0ME9EVTFJREl4TWt3eE1ETXVNekV5SURJeE1rTXhNRFF1TlRJeElESXhNaUF4TURRdU9USTBJREl4TXk0Mk1ESWdNVEF6TGpnMU5pQXlNVFF1TVRZMFdpSWdabWxzYkQwaWQyaHBkR1VpTHo0OGNHRjBhQ0JrUFNKTk1URTVMalUzTXlBeU1UWXVPVEF4VERreUxqWTJPU0F5TmpRdU5qQXlRemt5TGpBME1Ea2dNalkxTGpjeE5pQTVNQzQyTVRjeUlESTJOaTR4TVNBNE9TNDBPVGN4SURJMk5TNDBPRXcxT0M0eE1ESXhJREkwTnk0NE16RkROVFl1TlRNNE15QXlORFl1T1RVeUlEVTJMalV6TkRjZ01qUTBMamN5TWlBMU9DNHdPVFUySURJME15NDRNemhNTVRFeUxqSTJNeUF5TVRNdU1UVTVRekV4TXk0Mk1EUWdNakV5TGpRZ01URTFMakV5TXlBeU1USWdNVEUyTGpZMk9DQXlNVEpETVRFNUxqSXdPQ0F5TVRJZ01USXdMamd4TWlBeU1UUXVOekExSURFeE9TNDFOek1nTWpFMkxqa3dNVm9pSUdacGJHdzlJaU13TURRM1JrWWlMejQ4WkdWbWN6NDhjR0YwZEdWeWJpQnBaRDBpY0dGMGRHVnliakJmT1Rjd04xODFNakUxTmlJZ2NHRjBkR1Z5YmtOdmJuUmxiblJWYm1sMGN6MGliMkpxWldOMFFtOTFibVJwYm1kQ2IzZ2lJSGRwWkhSb1BTSXhJaUJvWldsbmFIUTlJakVpUGp4MWMyVWdlR3hwYm1zNmFISmxaajBpSTJsdFlXZGxNRjg1TnpBM1h6VXlNVFUySWlCMGNtRnVjMlp2Y20wOUluTmpZV3hsS0RBdU1EQXlJREF1TURBeU16YzFNeWtpTHo0OEwzQmhkSFJsY200K1BDOWtaV1p6UGp3dmMzWm5QZz09In0=", description),
            true
        );

        vm.expectRevert();
        ERC721(_nft).tokenURI(2);

        vm.stopPrank();

    }

    function _contains(string memory what, string memory where) pure private returns(bool found) {
        bytes memory whatBytes = bytes (what);
        bytes memory whereBytes = bytes (where);

        require(whereBytes.length >= whatBytes.length);

        found = false;
        for (uint i = 0; i <= whereBytes.length - whatBytes.length; i++) {
            bool flag = true;
            for (uint j = 0; j < whatBytes.length; j++)
                if (whereBytes [i + j] != whatBytes [j]) {
                    flag = false;
                    break;
                }
            if (flag) {
                found = true;
                break;
            }
        }
    }

    function testSetAccountRegistry() public {
        vm.startPrank(user);
        vm.expectRevert();
        walletFactory.setAccountRegistry(randomToken);
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        
        address _factory = walletFactory.accountRegistry();
        walletFactory.setAccountRegistry(randomToken);
        assertEq(walletFactory.accountRegistry(), randomToken);
        walletFactory.setAccountRegistry(_factory);
        vm.stopPrank();
    }

    function testSetWalletAccountImpl() public {
        vm.startPrank(user);
        vm.expectRevert();
        walletFactory.setWalletImpl(randomToken);
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        address _factory = walletFactory.walletImpl();
        walletFactory.setWalletImpl(randomToken);
        assertEq(walletFactory.walletImpl(), randomToken);
        walletFactory.setWalletImpl(_factory);
        vm.stopPrank();
    }

    function testSetFeeReceiver() public {
        vm.startPrank(user);
        vm.expectRevert();
        walletFactory.setFeeReceiver(user);
        vm.stopPrank();

        vm.startPrank(defaultAdmin);
        walletFactory.setFeeReceiver(user);
        assertEq(walletFactory.feeReceiver(), user);
        vm.stopPrank();
    }

    event WalletCreated(
        address indexed account,
        address indexed nftCollection,
        uint256 tokenId,
        address receiver,
        uint256 chainId
    );

    function testCreateTBA() public {
        
        vm.startPrank(user);
        vm.expectEmit(false, true, true, true);

        // We emit the event we expect to see.
        emit WalletCreated(address(this), address(usdt), 1, address(0), 1);

        walletFactory.createTBA(address(usdt), 1, 1);
        vm.stopPrank();
    }

}
