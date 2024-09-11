// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/StdAssertions.sol";
import "forge-std/console.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "./WalletFactory.base.sol";
import "../../../src/terms/VePendleTerm.sol";
import {NFTAccountDelegable} from "../../../src/accounts/NFTAccountDelegable.sol";
import "../../../src/helpers/NFTDescriptor/DelegationURI/NFTDelegationDescriptor.sol";

contract WalletFactoryUtilsTest is Test, WalletFactoryBaseTest {
    address randomAdrr = vm.addr(99999);
    address randomToken = vm.addr(99999);
    NFTDelegationDescriptor delegationDescriptor = NFTDelegationDescriptor(Upgrades.deployUUPSProxy(
        "NFTDelegationDescriptor.sol:NFTDelegationDescriptor",
        abi.encodeCall(
            NFTDelegationDescriptor.initialize,
            (address(this))
        )
    ));
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
        walletFactory.create(_nft);

        
        string memory description = ERC721(_nft).tokenURI(0);
        assertEq(
            _contains("data:application/json;base64,eyJuYW1lIjoicmFuZG9tICMwIiwgImRlc2NyaXB0aW9uIjoiVGhpcyBORlQgc2lnbmlmaWVzIHRoZSBvd25lcnNoaXAgb2YgYW4gYWNjb3VudCBjb250YWluaW5nIGNyeXB0byBhc3NldHMgb3Igb2ZmLWNoYWluIHBvaW50cywga25vd24gYXMgYSBWZW1vIE5GVCBBY2NvdW50IGZvbGxvd2luZyB0aGUgRVJDLTY1NTEgc3RhbmRhcmQuIE9ubHkgTkZUIGhvbGRlciBoYXMgY29tcGxldGUgY29udHJvbCBvdmVyIHRoZSBhc3NldHMgaW4gdGhlIGFjY291bnQuIEFkZGl0aW9uYWxseSwgdGhleSBjYW4gdHJhbnNmZXIgdGhlIGFjY291bnQgdG8gb3RoZXJzIGJ5IHRyYW5zZmVycmluZyBvciBzZWxsaW5nIE5GVCBvbiB0aGUgc2Vjb25kYXJ5IG1hcmtldC5cblxuIFZlbW8gQWNjb3VudCBhZGRyZXNzIGxpbmtlZCB0byB0aGlzIE5GVDogMHg2MmYyMjIwZWQ2Y2FhYmZlNTZkYTdiNzljMTdkZTYzYjI3OTBlNGQ2XG5cbkZvciBtb3JlIGRldGFpbHMsIHBsZWFzZSB2aXNpdCBodHRwczovL3ZlbW8ubmV0d29yay9cblxu4pqg77iPIERJU0NMQUlNRVI6IEl0IGlzIGhpZ2hseSByZWNvbW1lbmRlZCB0byB2ZXJpZnkgdGhlIGFzc2V0cyBpbiB0aGUgTkZUIEFjY291bnQgb24gVmVtbyBOZXR3b3JrIHdlYnNpdGUgYmVmb3JlIG1ha2luZyBhbnkgZGVjaXNpb25zLiIsICJpbWFnZSI6ICJkYXRhOmltYWdlL3N2Zyt4bWw7YmFzZTY0LFBITjJaeUIzYVdSMGFEMGlOVEF3SWlCb1pXbG5hSFE5SWpVd01DSWdkbWxsZDBKdmVEMGlNQ0F3SURVd01DQTFNREFpSUdacGJHdzlJbTV2Ym1VaUlIaHRiRzV6UFNKb2RIUndPaTh2ZDNkM0xuY3pMbTl5Wnk4eU1EQXdMM04yWnlJZ2VHMXNibk02ZUd4cGJtczlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5MekU1T1RrdmVHeHBibXNpUGp4eVpXTjBJSGRwWkhSb1BTSTFNREFpSUdobGFXZG9kRDBpTlRBd0lpQnllRDBpTWpRaUlHWnBiR3c5SWlNek9UUkZPRFlpTHo0OFp5QnpkSGxzWlQwaWJXbDRMV0pzWlc1a0xXMXZaR1U2YzJOeVpXVnVJajQ4Y21WamRDQjNhV1IwYUQwaU5UQXdJaUJvWldsbmFIUTlJalF5TVNJZ1ptbHNiRDBpZFhKc0tDTndZWFIwWlhKdU1GODVOekEzWHpVeU1UVTJLU0l2UGp3dlp6NDhjR0YwYUNCa1BTSk5NQ0F4TnpCSU1UTTJRekUwT1M0eU5UVWdNVGN3SURFMk1DQXhPREF1TnpRMUlERTJNQ0F4T1RSV016QTJRekUyTUNBek1Ua3VNalUxSURFME9TNHlOVFVnTXpNd0lERXpOaUF6TXpCSU1GWXhOekJhSWlCbWFXeHNQU0ozYUdsMFpTSWdabWxzYkMxdmNHRmphWFI1UFNJd0xqRWlMejQ4ZEdWNGRDQm1hV3hzUFNKM2FHbDBaU0lnWm1sc2JDMXZjR0ZqYVhSNVBTSXdMalVpSUhodGJEcHpjR0ZqWlQwaWNISmxjMlZ5ZG1VaUlITjBlV3hsUFNKM2FHbDBaUzF6Y0dGalpUb2djSEpsSWlCbWIyNTBMV1poYldsc2VUMGlWWEppWVc1cGMzUWlJR1p2Ym5RdGMybDZaVDBpTWpBaUlHWnZiblF0ZDJWcFoyaDBQU0kxTURBaUlHeGxkSFJsY2kxemNHRmphVzVuUFNJd0xqWmxiU0krUEhSemNHRnVJSGc5SWpVMklpQjVQU0kwTWpnaVBsQlBWMFZTUlVRZ1Fsa2dWa1ZOVHp3dmRITndZVzQrUEM5MFpYaDBQangwWlhoMElHWnBiR3c5SW5kb2FYUmxJaUI0Yld3NmMzQmhZMlU5SW5CeVpYTmxjblpsSWlCemRIbHNaVDBpZDJocGRHVXRjM0JoWTJVNklIQnlaU0lnWm05dWRDMW1ZVzFwYkhrOUlsVnlZbUZ1YVhOMElpQm1iMjUwTFhOcGVtVTlJakk0SWlCbWIyNTBMWGRsYVdkb2REMGlOVEF3SWlCc1pYUjBaWEl0YzNCaFkybHVaejBpTUdWdElqNDhkSE53WVc0Z2VEMGlNVGsySWlCNVBTSXlOamt1T0NJK1RrWlVJRUZqWTI5MWJuUThMM1J6Y0dGdVBqd3ZkR1Y0ZEQ0OGRHVjRkQ0JtYVd4c1BTSjNhR2wwWlNJZ2VHMXNPbk53WVdObFBTSndjbVZ6WlhKMlpTSWdjM1I1YkdVOUluZG9hWFJsTFhOd1lXTmxPaUJ3Y21VaUlHWnZiblF0Wm1GdGFXeDVQU0pWY21KaGJtbHpkQ0lnWm05dWRDMXphWHBsUFNJME9DSWdabTl1ZEMxM1pXbG5hSFE5SWpZd01DSWdiR1YwZEdWeUxYTndZV05wYm1jOUlqQmxiU0krUEhSemNHRnVJSGc5SWpFNU5pSWdlVDBpTWpFeUxqTWlQbFpsYlc4OEwzUnpjR0Z1UGp3dmRHVjRkRDQ4ZEdWNGRDQm1hV3hzUFNKM2FHbDBaU0lnZUcxc09uTndZV05sUFNKd2NtVnpaWEoyWlNJZ2MzUjViR1U5SW5kb2FYUmxMWE53WVdObE9pQndjbVVpSUdadmJuUXRabUZ0YVd4NVBTSlZjbUpoYm1semRDSWdabTl1ZEMxemFYcGxQU0l6TWlJZ1ptOXVkQzEzWldsbmFIUTlJalV3TUNJZ2JHVjBkR1Z5TFhOd1lXTnBibWM5SWpCbGJTSStQSFJ6Y0dGdUlIZzlJalUySWlCNVBTSTVPQzR5SWo0ak1Ed3ZkSE53WVc0K1BDOTBaWGgwUGp4MFpYaDBJR1pwYkd3OUluZG9hWFJsSWlCbWFXeHNMVzl3WVdOcGRIazlJakF1TmlJZ2VHMXNPbk53WVdObFBTSndjbVZ6WlhKMlpTSWdjM1I1YkdVOUluZG9hWFJsTFhOd1lXTmxPaUJ3Y21VaUlHWnZiblF0Wm1GdGFXeDVQU0pWY21KaGJtbHpkQ0lnWm05dWRDMXphWHBsUFNJeU9DSWdiR1YwZEdWeUxYTndZV05wYm1jOUlqQXVNRFZsYlNJK1BIUnpjR0Z1SUhnOUlqRTVOaUlnZVQwaU16RTNMamdpUGpCNE5qSm1MaTR1WlRSa05qd3ZkSE53WVc0K1BDOTBaWGgwUGp4d1lYUm9JR1E5SWswNE9DNDJOakEzSURJM01pNDJNRFpNT0RBdU5USTFNeUF5T0RZdU9ETTBRemM1TGpZeE16Y2dNamc0TGpReU9TQTNOeTR5TnpZNElESTRPQzR6TnpjZ056WXVORE0zTmlBeU9EWXVOelEwVERZeExqRXpNVFFnTWpVMkxqazJORU0yTUM0Mk1EazVJREkxTlM0NU5Ea2dOakV1TnpNMk1pQXlOVFF1T0RneUlEWXlMamN6TmprZ01qVTFMalEwTWt3NE55NDNPRE01SURJMk9TNDBOelJET0RndU9EazVPQ0F5TnpBdU1EazVJRGc1TGpJNU1qTWdNamN4TGpVd01TQTRPQzQyTmpBM0lESTNNaTQyTURaYUlpQm1hV3hzUFNKM2FHbDBaU0l2UGp4d1lYUm9JR1E5SWsweE1ETXVPRFUySURJeE5DNHhOalJNTlRVdU56WTJOU0F5TXprdU5EUXpRelUwTGpBME1qSWdNalF3TGpNME9TQTFNUzQ1TURJMElESXpPUzQyTnpVZ05URXVNREkwT0NBeU16Y3VPVFE0VERRd0xqTTNOakVnTWpFMkxqazVOME16T1M0eU1URWdNakUwTGpjd05DQTBNQzQ0T1RNNElESXhNaUEwTXk0ME9EVTFJREl4TWt3eE1ETXVNekV5SURJeE1rTXhNRFF1TlRJeElESXhNaUF4TURRdU9USTBJREl4TXk0Mk1ESWdNVEF6TGpnMU5pQXlNVFF1TVRZMFdpSWdabWxzYkQwaWQyaHBkR1VpTHo0OGNHRjBhQ0JrUFNKTk1URTVMalUzTXlBeU1UWXVPVEF4VERreUxqWTJPU0F5TmpRdU5qQXlRemt5TGpBME1Ea2dNalkxTGpjeE5pQTVNQzQyTVRjeUlESTJOaTR4TVNBNE9TNDBPVGN4SURJMk5TNDBPRXcxT0M0eE1ESXhJREkwTnk0NE16RkROVFl1TlRNNE15QXlORFl1T1RVeUlEVTJMalV6TkRjZ01qUTBMamN5TWlBMU9DNHdPVFUySURJME15NDRNemhNTVRFeUxqSTJNeUF5TVRNdU1UVTVRekV4TXk0Mk1EUWdNakV5TGpRZ01URTFMakV5TXlBeU1USWdNVEUyTGpZMk9DQXlNVEpETVRFNUxqSXdPQ0F5TVRJZ01USXdMamd4TWlBeU1UUXVOekExSURFeE9TNDFOek1nTWpFMkxqa3dNVm9pSUdacGJHdzlJaU13TURRM1JrWWlMejQ4WkdWbWN6NDhjR0YwZEdWeWJpQnBaRDBpY0dGMGRHVnliakJmT1Rjd04xODFNakUxTmlJZ2NHRjBkR1Z5YmtOdmJuUmxiblJWYm1sMGN6MGliMkpxWldOMFFtOTFibVJwYm1kQ2IzZ2lJSGRwWkhSb1BTSXhJaUJvWldsbmFIUTlJakVpUGp4MWMyVWdlR3hwYm1zNmFISmxaajBpSTJsdFlXZGxNRjg1TnpBM1h6VXlNVFUySWlCMGNtRnVjMlp2Y20wOUluTmpZV3hsS0RBdU1EQXlJREF1TURBeU16YzFNeWtpTHo0OEwzQmhkSFJsY200K1BDOWtaV1p6UGp3dmMzWm5QZz09In0=", description),
            true
        );

        vm.expectRevert();
        ERC721(_nft).tokenURI(2);

        vm.stopPrank();

    }

    function testCreateDelegationCollection() public {
        vm.startPrank(defaultAdmin);
        address _nft = walletFactory.createWalletCollection(
            uint160(randomToken),
            "random",
            "random",
            address(vemoCollectionDescriptor)
        );
        VePendleTerm vePendleTerm = new VePendleTerm();

        address delegateCollection = walletFactory.createDelegateCollection(
            "A",
            "B",
            address(delegationDescriptor),
            address(vePendleTerm),
            _nft
        );

        (uint256 tokenId, address _tba) = walletFactory.create(_nft);
        NFTAccountDelegable(payable(_tba)).delegate(delegateCollection, defaultAdmin);

        string memory description = ERC721(delegateCollection).tokenURI(tokenId);
        assertEq(
            _contains("data:application/json;base64,eyJuYW1lIjoiQSAjMCIsICJkZXNjcmlwdGlvbiI6Ik93bmluZyB0aGlzIE5GVCBncmFudHMgdGhlIGhvbGRlciB0aGUgYXV0aG9yaXR5IHRvIGNhc3Qgdm90ZXMgYW5kIGhhcnZlc3QgcmV3YXJkcyBmcm9tIFBlbmRsZSBGaW5hbmNlIG9uIGJlaGFsZiBvZiB2ZVBFTkRMRSBvd25lciBmb3IgYSBzcGVjaWZpZWQgZHVyYXRpb24sIHVwIHRvIHRoZSBleHBpcmF0aW9uIGRhdGUuIEhvd2V2ZXIsIHRoZSBob2xkZXIncyBhY3Rpb25zIGFyZSBzdHJpY3RseSBsaW1pdGVkIHRvIHZlUGVuZGxlLXJlbGF0ZWQgYWN0aXZpdGllcy4gU3BlY2lmaWNhbGx5LCB0aGUgaG9sZGVyIGlzIHByb2hpYml0ZWQgZnJvbTogXG5cbi0gUmVuZXcgdGhlIGxvY2sgb24gUGVuZGxlIEZpbmFuY2UuXG4tIFRyYW5zZmVycmluZyBvciBidXJuaW5nIGFzc2V0cyBmcm9tIFZlbW8gTkZUIEFjY291bnRcbi0gU2lnbmluZyBFSVAtNzIxIHNpZ25hdHVyZXNcbi0gQXBwcm92aW5nIHRva2VuIHRyYW5zYWN0aW9uc1xuLSBJbnRlcmFjdGluZyB3aXRoIHNtYXJ0IGNvbnRyYWN0cyB1bmFmZmlsaWF0ZWQgd2l0aCBQZW5kbGUgRmluYW5jZVxuXG5WZW1vIE5GVCBBY2NvdW50IGFkZHJlc3MgaG9sZGluZyB2ZVBFTkRMRSBpczogMHg2MmYyMjIwZWQ2Y2FhYmZlNTZkYTdiNzljMTdkZTYzYjI3OTBlNGQ2XG5cbkZvciBtb3JlIGRldGFpbHMsIHBsZWFzZSB2aXNpdCBodHRwczovL3ZlbW8ubmV0d29yay8gXG7imqDvuI8gRElTQ0xBSU1FUjogSXQgaXMgaGlnaGx5IHJlY29tbWVuZGVkIHRvIHZlcmlmeSB0aGUgYXNzZXRzIGFuZCBleHBpcmF0aW9uIGRhdGUgb2YgdmVQRU5ETEUgVm90ZXIgaW4gVmVtbyBORlQgQWNjb3VudCBvbiBWZW1vIE5ldHdvcmsgd2Vic2l0ZSBiZWZvcmUgbWFraW5nIGFueSBkZWNpc2lvbnMuIiwgImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjNhV1IwYUQwaU5UQXdJaUJvWldsbmFIUTlJalV3TUNJZ2RtbGxkMEp2ZUQwaU1DQXdJRFV3TUNBMU1EQWlJR1pwYkd3OUltNXZibVVpSUhodGJHNXpQU0pvZEhSd09pOHZkM2QzTG5jekxtOXlaeTh5TURBd0wzTjJaeUlnZUcxc2JuTTZlR3hwYm1zOUltaDBkSEE2THk5M2QzY3Vkek11YjNKbkx6RTVPVGt2ZUd4cGJtc2lQanh5WldOMElIZHBaSFJvUFNJMU1EQWlJR2hsYVdkb2REMGlOVEF3SWlCeWVEMGlNalFpSUdacGJHdzlJaU13UkRFek1VTWlMejQ4WnlCemRIbHNaVDBpYldsNExXSnNaVzVrTFcxdlpHVTZjMk55WldWdUlqNDhjbVZqZENCM2FXUjBhRDBpTlRBd0lpQm9aV2xuYUhROUlqUXlNU0lnZEhKaGJuTm1iM0p0UFNKdFlYUnlhWGdvTFRFZ01DQXdJREVnTlRBd0lEQXBJaUJtYVd4c1BTSjFjbXdvSTNCaGRIUmxjbTR3WHprNE56QmZNamN6TURFcElpOCtQQzluUGp4d1lYUm9JR1E5SWswd0lERTNNRWd4TXpaRE1UUTVMakkxTlNBeE56QWdNVFl3SURFNE1DNDNORFVnTVRZd0lERTVORll6TURaRE1UWXdJRE14T1M0eU5UVWdNVFE1TGpJMU5TQXpNekFnTVRNMklETXpNRWd3VmpFM01Gb2lJR1pwYkd3OUluZG9hWFJsSWlCbWFXeHNMVzl3WVdOcGRIazlJakF1TVNJdlBqeDBaWGgwSUdacGJHdzlJbmRvYVhSbElpQm1hV3hzTFc5d1lXTnBkSGs5SWpBdU15SWdlRzFzT25Od1lXTmxQU0p3Y21WelpYSjJaU0lnYzNSNWJHVTlJbmRvYVhSbExYTndZV05sT2lCd2NtVWlJR1p2Ym5RdFptRnRhV3g1UFNKVmNtSmhibWx6ZENJZ1ptOXVkQzF6YVhwbFBTSXlNQ0lnWm05dWRDMTNaV2xuYUhROUlqVXdNQ0lnYkdWMGRHVnlMWE53WVdOcGJtYzlJakF1Tm1WdElqNDhkSE53WVc0Z2VEMGlOek1pSUhrOUlqUTBPQ0krVUU5WFJWSkZSQ0JDV1NCV1JVMVBQQzkwYzNCaGJqNDhMM1JsZUhRK1BIUmxlSFFnWm1sc2JEMGlkMmhwZEdVaUlIaHRiRHB6Y0dGalpUMGljSEpsYzJWeWRtVWlJSE4wZVd4bFBTSjNhR2wwWlMxemNHRmpaVG9nY0hKbElpQm1iMjUwTFdaaGJXbHNlVDBpVlhKaVlXNXBjM1FpSUdadmJuUXRjMmw2WlQwaU1qZ2lJR1p2Ym5RdGQyVnBaMmgwUFNJMU1EQWlJR3hsZEhSbGNpMXpjR0ZqYVc1blBTSXdaVzBpUGp4MGMzQmhiaUI0UFNJeE9UWWlJSGs5SWpJMk1TNDRJajVPUmxRZ1FXTmpiM1Z1ZER3dmRITndZVzQrUEM5MFpYaDBQangwWlhoMElHWnBiR3c5SW5kb2FYUmxJaUI0Yld3NmMzQmhZMlU5SW5CeVpYTmxjblpsSWlCemRIbHNaVDBpZDJocGRHVXRjM0JoWTJVNklIQnlaU0lnWm05dWRDMW1ZVzFwYkhrOUlsVnlZbUZ1YVhOMElpQm1iMjUwTFhOcGVtVTlJalE0SWlCbWIyNTBMWGRsYVdkb2REMGlOakF3SWlCc1pYUjBaWEl0YzNCaFkybHVaejBpTUdWdElqNDhkSE53WVc0Z2VEMGlOREFpSUhrOUlqRXhPQzQ0SWo1QlBDOTBjM0JoYmo0OEwzUmxlSFErUEhSbGVIUWdabWxzYkQwaWQyaHBkR1VpSUhodGJEcHpjR0ZqWlQwaWNISmxjMlZ5ZG1VaUlITjBlV3hsUFNKM2FHbDBaUzF6Y0dGalpUb2djSEpsSWlCbWIyNTBMV1poYldsc2VUMGlWWEppWVc1cGMzUWlJR1p2Ym5RdGMybDZaVDBpTkRRaUlHWnZiblF0ZDJWcFoyaDBQU0kxTURBaUlHeGxkSFJsY2kxemNHRmphVzVuUFNJd1pXMGlQangwYzNCaGJpQjRQU0l4T1RZaUlIazlJakl5TVM0MElqNGpNRHd2ZEhOd1lXNCtQQzkwWlhoMFBqeDBaWGgwSUdacGJHdzlJbmRvYVhSbElpQm1hV3hzTFc5d1lXTnBkSGs5SWpBdU5pSWdlRzFzT25Od1lXTmxQU0p3Y21WelpYSjJaU0lnYzNSNWJHVTlJbmRvYVhSbExYTndZV05sT2lCd2NtVWlJR1p2Ym5RdFptRnRhV3g1UFNKVmNtSmhibWx6ZENJZ1ptOXVkQzF6YVhwbFBTSXlPQ0lnYkdWMGRHVnlMWE53WVdOcGJtYzlJakF1TURWbGJTSStQSFJ6Y0dGdUlIZzlJakU1TmlJZ2VUMGlNekEzTGpnaVBqQjROakptTGk0dVpUUmtOand2ZEhOd1lXNCtQQzkwWlhoMFBqeHdZWFJvSUdROUlrMDRPQzQyTmpBM0lESTNNaTQyTURaTU9EQXVOVEkxTXlBeU9EWXVPRE0wUXpjNUxqWXhNemNnTWpnNExqUXlPU0EzTnk0eU56WTRJREk0T0M0ek56Y2dOell1TkRNM05pQXlPRFl1TnpRMFREWXhMakV6TVRRZ01qVTJMamsyTkVNMk1DNDJNRGs1SURJMU5TNDVORGtnTmpFdU56TTJNaUF5TlRRdU9EZ3lJRFl5TGpjek5qa2dNalUxTGpRME1rdzROeTQzT0RNNUlESTJPUzQwTnpSRE9EZ3VPRGs1T0NBeU56QXVNRGs1SURnNUxqSTVNak1nTWpjeExqVXdNU0E0T0M0Mk5qQTNJREkzTWk0Mk1EWmFJaUJtYVd4c1BTSjNhR2wwWlNJdlBqeHdZWFJvSUdROUlrMHhNRE11T0RVMklESXhOQzR4TmpSTU5UVXVOelkyTlNBeU16a3VORFF6UXpVMExqQTBNaklnTWpRd0xqTTBPU0ExTVM0NU1ESTBJREl6T1M0Mk56VWdOVEV1TURJME9DQXlNemN1T1RRNFREUXdMak0zTmpFZ01qRTJMams1TjBNek9TNHlNVEVnTWpFMExqY3dOQ0EwTUM0NE9UTTRJREl4TWlBME15NDBPRFUxSURJeE1rd3hNRE11TXpFeUlESXhNa014TURRdU5USXhJREl4TWlBeE1EUXVPVEkwSURJeE15NDJNRElnTVRBekxqZzFOaUF5TVRRdU1UWTBXaUlnWm1sc2JEMGlkMmhwZEdVaUx6NDhjR0YwYUNCa1BTSk5NVEU1TGpVM015QXlNVFl1T1RBeFREa3lMalkyT1NBeU5qUXVOakF5UXpreUxqQTBNRGtnTWpZMUxqY3hOaUE1TUM0Mk1UY3lJREkyTmk0eE1TQTRPUzQwT1RjeElESTJOUzQwT0V3MU9DNHhNREl4SURJME55NDRNekZETlRZdU5UTTRNeUF5TkRZdU9UVXlJRFUyTGpVek5EY2dNalEwTGpjeU1pQTFPQzR3T1RVMklESTBNeTQ0TXpoTU1URXlMakkyTXlBeU1UTXVNVFU1UXpFeE15NDJNRFFnTWpFeUxqUWdNVEUxTGpFeU15QXlNVElnTVRFMkxqWTJPQ0F5TVRKRE1URTVMakl3T0NBeU1USWdNVEl3TGpneE1pQXlNVFF1TnpBMUlERXhPUzQxTnpNZ01qRTJMamt3TVZvaUlHWnBiR3c5SWlNd01EUTNSa1lpTHo0OGNHRjBhQ0JrUFNKTk5EQWdNRWd5TURGV01qaERNakF4SURNMExqWXlOelFnTVRrMUxqWXlOeUEwTUNBeE9Ea2dOREJJTlRKRE5EVXVNemN5TmlBME1DQTBNQ0F6TkM0Mk1qYzBJRFF3SURJNFZqQmFJaUJtYVd4c1BTSWpNREEwTjBaR0lpOCtQSFJsZUhRZ1ptbHNiRDBpZDJocGRHVWlJSGh0YkRwemNHRmpaVDBpY0hKbGMyVnlkbVVpSUhOMGVXeGxQU0ozYUdsMFpTMXpjR0ZqWlRvZ2NISmxJaUJtYjI1MExXWmhiV2xzZVQwaVRXOXVkSE5sY25KaGRDQlVhR2x1SWlCbWIyNTBMWE5wZW1VOUlqSXlJaUJtYjI1MExYZGxhV2RvZEQwaU5qQXdJaUJzWlhSMFpYSXRjM0JoWTJsdVp6MGlNR1Z0SWo0OGRITndZVzRnZUQwaU5qQWlJSGs5SWpJM0xqZzROeUkrUkVWTVJVZEJWRVU4TDNSemNHRnVQand2ZEdWNGRENDhaR1ZtY3o0OGNHRjBkR1Z5YmlCcFpEMGljR0YwZEdWeWJqQmZPVGczTUY4eU56TXdNU0lnY0dGMGRHVnlia052Ym5SbGJuUlZibWwwY3owaWIySnFaV04wUW05MWJtUnBibWRDYjNnaUlIZHBaSFJvUFNJeElpQm9aV2xuYUhROUlqRWlQangxYzJVZ2VHeHBibXM2YUhKbFpqMGlJMmx0WVdkbE1GODVPRGN3WHpJM016QXhJaUIwY21GdWMyWnZjbTA5SW5OallXeGxLREF1TURBeUlEQXVNREF5TXpjMU15a2lMejQ4TDNCaGRIUmxjbTQrUEM5a1pXWnpQand2YzNablBnPT0ifQ==", description),
            true
        );

        vm.expectRevert();
        ERC721(_nft).tokenURI(tokenId + 1);

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
