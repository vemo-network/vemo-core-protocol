// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "../../../src/helpers/NFTDescriptor/DelegationURI/NFTDelegationDescriptor.sol";
import "../../mock/USDT.sol";

contract NFTDelegateDescriptorTest is Test {
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
            collectionName: "vePendle voter",
            tba: address(this)
        });

        string memory description = globalDescriptor.constructTokenURI(params);
        
        assertEq(
            contains("data:application/json;base64,eyJuYW1lIjoidmVQZW5kbGUgdm90ZXIgIzEiLCAiZGVzY3JpcHRpb24iOiJPd25pbmcgdGhpcyBORlQgZ3JhbnRzIHRoZSBob2xkZXIgdGhlIGF1dGhvcml0eSB0byBjYXN0IHZvdGVzIGFuZCBoYXJ2ZXN0IHJld2FyZHMgZnJvbSBQZW5kbGUgRmluYW5jZSBvbiBiZWhhbGYgb2YgdmVQRU5ETEUgb3duZXIgZm9yIGEgc3BlY2lmaWVkIGR1cmF0aW9uLCB1cCB0byB0aGUgZXhwaXJhdGlvbiBkYXRlLiBIb3dldmVyLCB0aGUgaG9sZGVyJ3MgYWN0aW9ucyBhcmUgc3RyaWN0bHkgbGltaXRlZCB0byB2ZVBlbmRsZS1yZWxhdGVkIGFjdGl2aXRpZXMuIFNwZWNpZmljYWxseSwgdGhlIGhvbGRlciBpcyBwcm9oaWJpdGVkIGZyb206IFxuXG4tIFJlbmV3IHRoZSBsb2NrIG9uIFBlbmRsZSBGaW5hbmNlLlxuLSBUcmFuc2ZlcnJpbmcgb3IgYnVybmluZyBhc3NldHMgZnJvbSBWZW1vIE5GVCBBY2NvdW50XG4tIFNpZ25pbmcgRUlQLTcyMSBzaWduYXR1cmVzXG4tIEFwcHJvdmluZyB0b2tlbiB0cmFuc2FjdGlvbnNcbi0gSW50ZXJhY3Rpbmcgd2l0aCBzbWFydCBjb250cmFjdHMgdW5hZmZpbGlhdGVkIHdpdGggUGVuZGxlIEZpbmFuY2VcblxuVmVtbyBORlQgQWNjb3VudCBhZGRyZXNzIGhvbGRpbmcgdmVQRU5ETEUgaXM6IDB4N2ZhOTM4NWJlMTAyYWMzZWFjMjk3NDgzZGQ2MjMzZDYyYjNlMTQ5NlxuXG5Gb3IgbW9yZSBkZXRhaWxzLCBwbGVhc2UgdmlzaXQgaHR0cHM6Ly92ZW1vLm5ldHdvcmsvIFxu4pqg77iPIERJU0NMQUlNRVI6IEl0IGlzIGhpZ2hseSByZWNvbW1lbmRlZCB0byB2ZXJpZnkgdGhlIGFzc2V0cyBhbmQgZXhwaXJhdGlvbiBkYXRlIG9mIHZlUEVORExFIFZvdGVyIGluIFZlbW8gTkZUIEFjY291bnQgb24gVmVtbyBOZXR3b3JrIHdlYnNpdGUgYmVmb3JlIG1ha2luZyBhbnkgZGVjaXNpb25zLiIsICJpbWFnZSI6ICJkYXRhOmltYWdlL3N2Zyt4bWw7YmFzZTY0LFBITjJaeUIzYVdSMGFEMGlOVEF3SWlCb1pXbG5hSFE5SWpVd01DSWdkbWxsZDBKdmVEMGlNQ0F3SURVd01DQTFNREFpSUdacGJHdzlJbTV2Ym1VaUlIaHRiRzV6UFNKb2RIUndPaTh2ZDNkM0xuY3pMbTl5Wnk4eU1EQXdMM04yWnlJZ2VHMXNibk02ZUd4cGJtczlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5MekU1T1RrdmVHeHBibXNpUGp4eVpXTjBJSGRwWkhSb1BTSTFNREFpSUdobGFXZG9kRDBpTlRBd0lpQnllRDBpTWpRaUlHWnBiR3c5SWlNd1JERXpNVU1pTHo0OFp5QnpkSGxzWlQwaWJXbDRMV0pzWlc1a0xXMXZaR1U2YzJOeVpXVnVJajQ4Y21WamRDQjNhV1IwYUQwaU5UQXdJaUJvWldsbmFIUTlJalF5TVNJZ2RISmhibk5tYjNKdFBTSnRZWFJ5YVhnb0xURWdNQ0F3SURFZ05UQXdJREFwSWlCbWFXeHNQU0oxY213b0kzQmhkSFJsY200d1h6azROekJmTWpjek1ERXBJaTgrUEM5blBqeHdZWFJvSUdROUlrMHdJREUzTUVneE16WkRNVFE1TGpJMU5TQXhOekFnTVRZd0lERTRNQzQzTkRVZ01UWXdJREU1TkZZek1EWkRNVFl3SURNeE9TNHlOVFVnTVRRNUxqSTFOU0F6TXpBZ01UTTJJRE16TUVnd1ZqRTNNRm9pSUdacGJHdzlJbmRvYVhSbElpQm1hV3hzTFc5d1lXTnBkSGs5SWpBdU1TSXZQangwWlhoMElHWnBiR3c5SW5kb2FYUmxJaUJtYVd4c0xXOXdZV05wZEhrOUlqQXVNeUlnZUcxc09uTndZV05sUFNKd2NtVnpaWEoyWlNJZ2MzUjViR1U5SW5kb2FYUmxMWE53WVdObE9pQndjbVVpSUdadmJuUXRabUZ0YVd4NVBTSlZjbUpoYm1semRDSWdabTl1ZEMxemFYcGxQU0l5TUNJZ1ptOXVkQzEzWldsbmFIUTlJalV3TUNJZ2JHVjBkR1Z5TFhOd1lXTnBibWM5SWpBdU5tVnRJajQ4ZEhOd1lXNGdlRDBpTnpNaUlIazlJalEwT0NJK1VFOVhSVkpGUkNCQ1dTQldSVTFQUEM5MGMzQmhiajQ4TDNSbGVIUStQSFJsZUhRZ1ptbHNiRDBpZDJocGRHVWlJSGh0YkRwemNHRmpaVDBpY0hKbGMyVnlkbVVpSUhOMGVXeGxQU0ozYUdsMFpTMXpjR0ZqWlRvZ2NISmxJaUJtYjI1MExXWmhiV2xzZVQwaVZYSmlZVzVwYzNRaUlHWnZiblF0YzJsNlpUMGlNamdpSUdadmJuUXRkMlZwWjJoMFBTSTFNREFpSUd4bGRIUmxjaTF6Y0dGamFXNW5QU0l3WlcwaVBqeDBjM0JoYmlCNFBTSXhPVFlpSUhrOUlqSTJNUzQ0SWo1T1JsUWdRV05qYjNWdWREd3ZkSE53WVc0K1BDOTBaWGgwUGp4MFpYaDBJR1pwYkd3OUluZG9hWFJsSWlCNGJXdzZjM0JoWTJVOUluQnlaWE5sY25abElpQnpkSGxzWlQwaWQyaHBkR1V0YzNCaFkyVTZJSEJ5WlNJZ1ptOXVkQzFtWVcxcGJIazlJbFZ5WW1GdWFYTjBJaUJtYjI1MExYTnBlbVU5SWpRNElpQm1iMjUwTFhkbGFXZG9kRDBpTmpBd0lpQnNaWFIwWlhJdGMzQmhZMmx1WnowaU1HVnRJajQ4ZEhOd1lXNGdlRDBpTkRBaUlIazlJakV4T0M0NElqNTJaVkJsYm1Sc1pTQjJiM1JsY2p3dmRITndZVzQrUEM5MFpYaDBQangwWlhoMElHWnBiR3c5SW5kb2FYUmxJaUI0Yld3NmMzQmhZMlU5SW5CeVpYTmxjblpsSWlCemRIbHNaVDBpZDJocGRHVXRjM0JoWTJVNklIQnlaU0lnWm05dWRDMW1ZVzFwYkhrOUlsVnlZbUZ1YVhOMElpQm1iMjUwTFhOcGVtVTlJalEwSWlCbWIyNTBMWGRsYVdkb2REMGlOVEF3SWlCc1pYUjBaWEl0YzNCaFkybHVaejBpTUdWdElqNDhkSE53WVc0Z2VEMGlNVGsySWlCNVBTSXlNakV1TkNJK0l6RThMM1J6Y0dGdVBqd3ZkR1Y0ZEQ0OGRHVjRkQ0JtYVd4c1BTSjNhR2wwWlNJZ1ptbHNiQzF2Y0dGamFYUjVQU0l3TGpZaUlIaHRiRHB6Y0dGalpUMGljSEpsYzJWeWRtVWlJSE4wZVd4bFBTSjNhR2wwWlMxemNHRmpaVG9nY0hKbElpQm1iMjUwTFdaaGJXbHNlVDBpVlhKaVlXNXBjM1FpSUdadmJuUXRjMmw2WlQwaU1qZ2lJR3hsZEhSbGNpMXpjR0ZqYVc1blBTSXdMakExWlcwaVBqeDBjM0JoYmlCNFBTSXhPVFlpSUhrOUlqTXdOeTQ0SWo0d2VEZG1ZUzR1TGpFME9UWThMM1J6Y0dGdVBqd3ZkR1Y0ZEQ0OGNHRjBhQ0JrUFNKTk9EZ3VOall3TnlBeU56SXVOakEyVERnd0xqVXlOVE1nTWpnMkxqZ3pORU0zT1M0Mk1UTTNJREk0T0M0ME1qa2dOemN1TWpjMk9DQXlPRGd1TXpjM0lEYzJMalF6TnpZZ01qZzJMamMwTkV3Mk1TNHhNekUwSURJMU5pNDVOalJETmpBdU5qQTVPU0F5TlRVdU9UUTVJRFl4TGpjek5qSWdNalUwTGpnNE1pQTJNaTQzTXpZNUlESTFOUzQwTkRKTU9EY3VOemd6T1NBeU5qa3VORGMwUXpnNExqZzVPVGdnTWpjd0xqQTVPU0E0T1M0eU9USXpJREkzTVM0MU1ERWdPRGd1TmpZd055QXlOekl1TmpBMldpSWdabWxzYkQwaWQyaHBkR1VpTHo0OGNHRjBhQ0JrUFNKTk1UQXpMamcxTmlBeU1UUXVNVFkwVERVMUxqYzJOalVnTWpNNUxqUTBNME0xTkM0d05ESXlJREkwTUM0ek5Ea2dOVEV1T1RBeU5DQXlNemt1TmpjMUlEVXhMakF5TkRnZ01qTTNMamswT0V3ME1DNHpOell4SURJeE5pNDVPVGRETXprdU1qRXhJREl4TkM0M01EUWdOREF1T0Rrek9DQXlNVElnTkRNdU5EZzFOU0F5TVRKTU1UQXpMak14TWlBeU1USkRNVEEwTGpVeU1TQXlNVElnTVRBMExqa3lOQ0F5TVRNdU5qQXlJREV3TXk0NE5UWWdNakUwTGpFMk5Gb2lJR1pwYkd3OUluZG9hWFJsSWk4K1BIQmhkR2dnWkQwaVRURXhPUzQxTnpNZ01qRTJMamt3TVV3NU1pNDJOamtnTWpZMExqWXdNa001TWk0d05EQTVJREkyTlM0M01UWWdPVEF1TmpFM01pQXlOall1TVRFZ09Ea3VORGszTVNBeU5qVXVORGhNTlRndU1UQXlNU0F5TkRjdU9ETXhRelUyTGpVek9ETWdNalEyTGprMU1pQTFOaTQxTXpRM0lESTBOQzQzTWpJZ05UZ3VNRGsxTmlBeU5ETXVPRE00VERFeE1pNHlOak1nTWpFekxqRTFPVU14TVRNdU5qQTBJREl4TWk0MElERXhOUzR4TWpNZ01qRXlJREV4Tmk0Mk5qZ2dNakV5UXpFeE9TNHlNRGdnTWpFeUlERXlNQzQ0TVRJZ01qRTBMamN3TlNBeE1Ua3VOVGN6SURJeE5pNDVNREZhSWlCbWFXeHNQU0lqTURBME4wWkdJaTgrUEhCaGRHZ2daRDBpVFRRd0lEQklNakF4VmpJNFF6SXdNU0F6TkM0Mk1qYzBJREU1TlM0Mk1qY2dOREFnTVRnNUlEUXdTRFV5UXpRMUxqTTNNallnTkRBZ05EQWdNelF1TmpJM05DQTBNQ0F5T0ZZd1dpSWdabWxzYkQwaUl6QXdORGRHUmlJdlBqeDBaWGgwSUdacGJHdzlJbmRvYVhSbElpQjRiV3c2YzNCaFkyVTlJbkJ5WlhObGNuWmxJaUJ6ZEhsc1pUMGlkMmhwZEdVdGMzQmhZMlU2SUhCeVpTSWdabTl1ZEMxbVlXMXBiSGs5SWsxdmJuUnpaWEp5WVhRZ1ZHaHBiaUlnWm05dWRDMXphWHBsUFNJeU1pSWdabTl1ZEMxM1pXbG5hSFE5SWpZd01DSWdiR1YwZEdWeUxYTndZV05wYm1jOUlqQmxiU0krUEhSemNHRnVJSGc5SWpZd0lpQjVQU0l5Tnk0NE9EY2lQa1JGVEVWSFFWUkZQQzkwYzNCaGJqNDhMM1JsZUhRK1BHUmxabk0rUEhCaGRIUmxjbTRnYVdROUluQmhkSFJsY200d1h6azROekJmTWpjek1ERWlJSEJoZEhSbGNtNURiMjUwWlc1MFZXNXBkSE05SW05aWFtVmpkRUp2ZFc1a2FXNW5RbTk0SWlCM2FXUjBhRDBpTVNJZ2FHVnBaMmgwUFNJeElqNDhkWE5sSUhoc2FXNXJPbWh5WldZOUlpTnBiV0ZuWlRCZk9UZzNNRjh5TnpNd01TSWdkSEpoYm5ObWIzSnRQU0p6WTJGc1pTZ3dMakF3TWlBd0xqQXdNak0zTlRNcElpOCtQQzl3WVhSMFpYSnVQand2WkdWbWN6NDhMM04yWno0PSJ9", description),
            true
        );
        vm.stopPrank();
    }

}
