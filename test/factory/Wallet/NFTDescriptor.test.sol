// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "../../../src/helpers/NFTDescriptor/DelegationURI/NFTDelegationDescriptor.sol";
import "../../mock/USDT.sol";

contract NFTDescriptorTest is Test {
    NFTDelegationDescriptor globalDescriptor;
    USDT usdt = new USDT();

    function setUp() public {
        globalDescriptor = NFTDelegationDescriptor(Upgrades.deployUUPSProxy(
            "NFTDelegationDescriptor.sol:NFTDelegationDescriptor",
            abi.encodeCall(
                NFTDelegationDescriptor.initialize,
                (address(this))
            )
        ));

        vm.stopPrank();
    }

    function contains(string memory what, string memory where) pure private returns(bool found) {
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

    function testGenerateDescriptionPart() public {
        INFTDelegationDescriptor.ConstructTokenURIParams memory params = INFTDelegationDescriptor.ConstructTokenURIParams({
            nftId: 1,
            nftAddress: address(this),
            collectionName: "NFTDescriptorTest",
            tba: address(this)
        });

        string memory description = globalDescriptor.constructTokenURI(params);
        
        assertEq(
            contains("data:application/json;base64,eyJuYW1lIjoiTkZURGVzY3JpcHRvclRlc3QgIzEiLCAiZGVzY3JpcHRpb24iOiJUaGlzIE5GVCwgcmVmZXJyZWQgdG8gYXMgYSBzbWFydCB3YWxsZXQgZGVsZWdhdGlvbiByb2xlLiBUaGUgaG9sZGVyIGhhcyB0aGUgYWJpbGl0eSB0byB2b3RlIG9uIGJlaGFsZiBvZiB0aGUgVEJBIG93bmVyLCBhbmQgY2FuIGFsc28gdHJhbnNmZXIgb3Igc2VsbCB0aGUgTkZUIGl0c2VsZiBvbiB0aGUgc2Vjb25kYXJ5IG1hcmtldC4gUmVhZCBtb3JlIG9uIGh0dHBzOi8vdmVtby5uZXR3b3JrLyBcblxuXG4g4pqg77iPIERJU0NMQUlNRVI6IEl0IGlzIGVzc2VudGlhbCB0byBleGVyY2lzZSBkdWUgZGlsaWdlbmNlIHdoZW4gYXNzZXNzaW5nIHRoaXMgc21hcnQgd2FsbGV0LiBQbGVhc2UgZW5zdXJlIHRoZSB0b2tlbiBhZGRyZXNzIGluIHRoZSBzbWFydCB3YWxsZXQgbWF0Y2hlcyB0aGUgZXhwZWN0ZWQgdG9rZW4sIGFzIHRva2VuIHN5bWJvbHMgbWF5IGJlIGltaXRhdGVkIiwgImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjNhV1IwYUQwaU1qZzBJaUJvWldsbmFIUTlJakV5TUNJZ2RtbGxkMEp2ZUQwaU1DQXdJREk0TkNBeE1qQWlJR1pwYkd3OUltNXZibVVpSUhodGJHNXpQU0pvZEhSd09pOHZkM2QzTG5jekxtOXlaeTh5TURBd0wzTjJaeUlnZUcxc2JuTTZlR3hwYm1zOUltaDBkSEE2THk5M2QzY3Vkek11YjNKbkx6RTVPVGt2ZUd4cGJtc2lQanh5WldOMElIZHBaSFJvUFNJeU9EUWlJR2hsYVdkb2REMGlNVEl3SWlCeWVEMGlNVElpSUdacGJHdzlJaU13UkRFek1VTWlMejQ4Y21WamRDQjNhV1IwYUQwaU1qZzBJaUJvWldsbmFIUTlJamsySWlCbWFXeHNQU0oxY213b0kzQmhkSFJsY200d1h6azJOVGRmTWpnd056WXBJaTgrUEhSbGVIUWdabWxzYkQwaWQyaHBkR1VpSUhodGJEcHpjR0ZqWlQwaWNISmxjMlZ5ZG1VaUlITjBlV3hsUFNKM2FHbDBaUzF6Y0dGalpUb2djSEpsSWlCbWIyNTBMV1poYldsc2VUMGlWWEppWVc1cGMzUWlJR1p2Ym5RdGMybDZaVDBpTWpBaUlHWnZiblF0ZDJWcFoyaDBQU0kyTURBaUlHeGxkSFJsY2kxemNHRmphVzVuUFNJd1pXMGlQangwYzNCaGJpQjRQU0k0TmlJZ2VUMGlOREF1TVNJK1RrWlVSR1Z6WTNKcGNIUnZjbFJsYzNROEwzUnpjR0Z1UGp3dmRHVjRkRDQ4ZEdWNGRDQm1hV3hzUFNKM2FHbDBaU0lnZUcxc09uTndZV05sUFNKd2NtVnpaWEoyWlNJZ2MzUjViR1U5SW5kb2FYUmxMWE53WVdObE9pQndjbVVpSUdadmJuUXRabUZ0YVd4NVBTSlZjbUpoYm1semRDSWdabTl1ZEMxemFYcGxQU0l4TWlJZ1ptOXVkQzEzWldsbmFIUTlJalV3TUNJZ2JHVjBkR1Z5TFhOd1lXTnBibWM5SWpCbGJTSStQSFJ6Y0dGdUlIZzlJamcySWlCNVBTSTJNQzR4SWo1VGJXRnlkQ0JYWVd4c1pYUWdRV1JrY21WemN6d3ZkSE53WVc0K1BDOTBaWGgwUGp4MFpYaDBJR1pwYkd3OUluZG9hWFJsSWlCNGJXdzZjM0JoWTJVOUluQnlaWE5sY25abElpQnpkSGxzWlQwaWQyaHBkR1V0YzNCaFkyVTZJSEJ5WlNJZ1ptOXVkQzFtWVcxcGJIazlJbFZ5WW1GdWFYTjBJaUJtYjI1MExYTnBlbVU5SWpFMklpQm1iMjUwTFhkbGFXZG9kRDBpTlRBd0lpQnNaWFIwWlhJdGMzQmhZMmx1WnowaU1HVnRJajQ4ZEhOd1lXNGdlRDBpTWpJMklpQjVQU0kxT1M0MklqNGpNVHd2ZEhOd1lXNCtQQzkwWlhoMFBqeDBaWGgwSUdacGJHdzlJbmRvYVhSbElpQm1hV3hzTFc5d1lXTnBkSGs5SWpBdU5pSWdlRzFzT25Od1lXTmxQU0p3Y21WelpYSjJaU0lnYzNSNWJHVTlJbmRvYVhSbExYTndZV05sT2lCd2NtVWlJR1p2Ym5RdFptRnRhV3g1UFNKVmNtSmhibWx6ZENJZ1ptOXVkQzF6YVhwbFBTSXhNaUlnYkdWMGRHVnlMWE53WVdOcGJtYzlJakF1TURWbGJTSStQSFJ6Y0dGdUlIZzlJakV4TUNJZ2VUMGlPVEF1TWlJK01IZzNabUV1TGk0eE5EazJQQzkwYzNCaGJqNDhMM1JsZUhRK1BIUmxlSFFnWm1sc2JEMGlJek5EUTBKRFJDSWdlRzFzT25Od1lXTmxQU0p3Y21WelpYSjJaU0lnYzNSNWJHVTlJbmRvYVhSbExYTndZV05sT2lCd2NtVWlJR1p2Ym5RdFptRnRhV3g1UFNKTmIyNTBjMlZ5Y21GMElGUm9hVzRpSUdadmJuUXRjMmw2WlQwaU1UQWlJR1p2Ym5RdGQyVnBaMmgwUFNJMU1EQWlJR3hsZEhSbGNpMXpjR0ZqYVc1blBTSXdaVzBpUGp4MGMzQmhiaUI0UFNJNExqQTNNekkwSWlCNVBTSXhNVEF1TlRnMUlqNUVSVXhGUjBGVVJUd3ZkSE53WVc0K1BDOTBaWGgwUGp4d1lYUm9JR1E5SWswd0lESTFTRFl5UXpZMkxqUXhPRE1nTWpVZ056QWdNamd1TlRneE55QTNNQ0F6TTFZNE4wTTNNQ0E1TVM0ME1UZ3pJRFkyTGpReE9ETWdPVFVnTmpJZ09UVklNRll5TlZvaUlHWnBiR3c5SW5kb2FYUmxJaUJtYVd4c0xXOXdZV05wZEhrOUlqQXVNRFVpTHo0OGNHRjBhQ0JrUFNKTk16Z3VORFkwTXlBMk9DNDVNak0wVERNMUxqSXhNREVnTnpRdU5UTTVPRU16TkM0NE5EVTFJRGMxTGpFMk9URWdNek11T1RFd055QTNOUzR4TkRnNUlETXpMalUzTlNBM05DNDFNRFF6VERJM0xqUTFNallnTmpJdU56UTRPRU15Tnk0eU5EUWdOakl1TXpRNE15QXlOeTQyT1RRMUlEWXhMamt5TnlBeU9DNHdPVFEzSURZeUxqRTBPRE5NTXpndU1URXpOaUEyTnk0Mk9EZERNemd1TlRVNU9TQTJOeTQ1TXpNM0lETTRMamN4TmprZ05qZ3VORGczTkNBek9DNDBOalF6SURZNExqa3lNelJhSWlCbWFXeHNQU0ozYUdsMFpTSXZQanh3WVhSb0lHUTlJazAwTkM0MU5ESXpJRFExTGpnMU5ERk1NalV1TXpBMk5pQTFOUzQ0TXpJNFF6STBMall4TmprZ05UWXVNVGt3TmlBeU15NDNOakVnTlRVdU9USTBNeUF5TXk0ME1EazVJRFUxTGpJME1qZE1NVGt1TVRVd05DQTBOaTQ1TnpJelF6RTRMalk0TkRRZ05EWXVNRFkzTkNBeE9TNHpOVGMxSURRMUlESXdMak01TkRJZ05EVk1ORFF1TXpJME5pQTBOVU0wTkM0NE1EZ3pJRFExSURRMExqazJPVFVnTkRVdU5qTXlOU0EwTkM0MU5ESXpJRFExTGpnMU5ERmFJaUJtYVd4c1BTSjNhR2wwWlNJdlBqeHdZWFJvSUdROUlrMDFNQzQ0TWpreElEUTJMamt6TkRkTU5EQXVNRFkzTmlBMk5TNDNOak01UXpNNUxqZ3hOalFnTmpZdU1qQXpOU0F6T1M0eU5EWTVJRFkyTGpNMU9TQXpPQzQzT1RnNUlEWTJMakV4TURWTU1qWXVNalF3T0NBMU9TNHhORE01UXpJMUxqWXhOVE1nTlRndU56azJPU0F5TlM0Mk1UTTVJRFUzTGpreE5qWWdNall1TWpNNE1pQTFOeTQxTmpjMlREUTNMamt3TlRFZ05EVXVORFUzTjBNME9DNDBOREUySURRMUxqRTFOemdnTkRrdU1EUTVJRFExSURRNUxqWTJOeklnTkRWRE5UQXVOamd6TXlBME5TQTFNUzR6TWpRMklEUTJMakEyTnpnZ05UQXVPREk1TVNBME5pNDVNelEzV2lJZ1ptbHNiRDBpSXpBd05EZEdSaUl2UGp4a1pXWnpQanh3WVhSMFpYSnVJR2xrUFNKd1lYUjBaWEp1TUY4NU5qVTNYekk0TURjMklpQndZWFIwWlhKdVEyOXVkR1Z1ZEZWdWFYUnpQU0p2WW1wbFkzUkNiM1Z1WkdsdVowSnZlQ0lnZDJsa2RHZzlJakVpSUdobGFXZG9kRDBpTVNJK1BIVnpaU0I0YkdsdWF6cG9jbVZtUFNJamFXMWhaMlV3WHprMk5UZGZNamd3TnpZaUlIUnlZVzV6Wm05eWJUMGljMk5oYkdVb01DNHdNRE0xTWpFeE15QXdMakF4TURReE5qY3BJaTgrUEM5d1lYUjBaWEp1UGp3dlpHVm1jejQ4TDNOMlp6ND0ifQ==", description),
            true
        );
        vm.stopPrank();
    }

}
