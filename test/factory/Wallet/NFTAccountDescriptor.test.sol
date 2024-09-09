// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "../../../src/helpers/NFTDescriptor/NFTAccount/NFTAccountDescriptor.sol";
import "../../mock/USDT.sol";

contract NFTAccountDescriptorTest is Test {
    NFTAccountDescriptor globalDescriptor;
    USDT usdt = new USDT();

    function setUp() public {
        globalDescriptor = NFTAccountDescriptor(Upgrades.deployUUPSProxy(
            "NFTAccountDescriptor.sol:NFTAccountDescriptor",
            abi.encodeCall(
                NFTAccountDescriptor.initialize,
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
        INFTAccountDescriptor.ConstructTokenURIParams memory params = INFTAccountDescriptor.ConstructTokenURIParams({
            nftId: 1,
            nftAddress: address(this),
            collectionName: "Vemo NFT Account",
            tba: address(this)
        });

        string memory description = globalDescriptor.constructTokenURI(params);
        
        assertEq(
            contains("data:application/json;base64,eyJuYW1lIjoiVmVtbyBORlQgQWNjb3VudCAjMSIsICJkZXNjcmlwdGlvbiI6IlRoaXMgTkZUIHNpZ25pZmllcyB0aGUgb3duZXJzaGlwIG9mIGFuIGFjY291bnQgY29udGFpbmluZyBjcnlwdG8gYXNzZXRzIG9yIG9mZi1jaGFpbiBwb2ludHMsIGtub3duIGFzIGEgVmVtbyBORlQgQWNjb3VudCBmb2xsb3dpbmcgdGhlIEVSQy02NTUxIHN0YW5kYXJkLiBPbmx5IE5GVCBob2xkZXIgaGFzIGNvbXBsZXRlIGNvbnRyb2wgb3ZlciB0aGUgYXNzZXRzIGluIHRoZSBhY2NvdW50LiBBZGRpdGlvbmFsbHksIHRoZXkgY2FuIHRyYW5zZmVyIHRoZSBhY2NvdW50IHRvIG90aGVycyBieSB0cmFuc2ZlcnJpbmcgb3Igc2VsbGluZyBORlQgb24gdGhlIHNlY29uZGFyeSBtYXJrZXQuXG5cbiBWZW1vIEFjY291bnQgYWRkcmVzcyBsaW5rZWQgdG8gdGhpcyBORlQ6IDB4N2ZhOTM4NWJlMTAyYWMzZWFjMjk3NDgzZGQ2MjMzZDYyYjNlMTQ5NlxuXG5Gb3IgbW9yZSBkZXRhaWxzLCBwbGVhc2UgdmlzaXQgaHR0cHM6Ly92ZW1vLm5ldHdvcmsvXG5cbuKaoO+4jyBESVNDTEFJTUVSOiBJdCBpcyBoaWdobHkgcmVjb21tZW5kZWQgdG8gdmVyaWZ5IHRoZSBhc3NldHMgaW4gdGhlIE5GVCBBY2NvdW50IG9uIFZlbW8gTmV0d29yayB3ZWJzaXRlIGJlZm9yZSBtYWtpbmcgYW55IGRlY2lzaW9ucy4iLCAiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpTlRBd0lpQm9aV2xuYUhROUlqVXdNQ0lnZG1sbGQwSnZlRDBpTUNBd0lEVXdNQ0ExTURBaUlHWnBiR3c5SW01dmJtVWlJSGh0Ykc1elBTSm9kSFJ3T2k4dmQzZDNMbmN6TG05eVp5OHlNREF3TDNOMlp5SWdlRzFzYm5NNmVHeHBibXM5SW1oMGRIQTZMeTkzZDNjdWR6TXViM0puTHpFNU9Ua3ZlR3hwYm1zaVBqeHlaV04wSUhkcFpIUm9QU0kxTURBaUlHaGxhV2RvZEQwaU5UQXdJaUJ5ZUQwaU1qUWlJR1pwYkd3OUlpTXpPVFJGT0RZaUx6NDhaeUJ6ZEhsc1pUMGliV2w0TFdKc1pXNWtMVzF2WkdVNmMyTnlaV1Z1SWo0OGNtVmpkQ0IzYVdSMGFEMGlOVEF3SWlCb1pXbG5hSFE5SWpReU1TSWdabWxzYkQwaWRYSnNLQ053WVhSMFpYSnVNRjg1TnpBM1h6VXlNVFUyS1NJdlBqd3ZaejQ4Y0dGMGFDQmtQU0pOTUNBeE56QklNVE0yUXpFME9TNHlOVFVnTVRjd0lERTJNQ0F4T0RBdU56UTFJREUyTUNBeE9UUldNekEyUXpFMk1DQXpNVGt1TWpVMUlERTBPUzR5TlRVZ016TXdJREV6TmlBek16QklNRll4TnpCYUlpQm1hV3hzUFNKM2FHbDBaU0lnWm1sc2JDMXZjR0ZqYVhSNVBTSXdMakVpTHo0OGRHVjRkQ0JtYVd4c1BTSjNhR2wwWlNJZ1ptbHNiQzF2Y0dGamFYUjVQU0l3TGpVaUlIaHRiRHB6Y0dGalpUMGljSEpsYzJWeWRtVWlJSE4wZVd4bFBTSjNhR2wwWlMxemNHRmpaVG9nY0hKbElpQm1iMjUwTFdaaGJXbHNlVDBpVlhKaVlXNXBjM1FpSUdadmJuUXRjMmw2WlQwaU1qQWlJR1p2Ym5RdGQyVnBaMmgwUFNJMU1EQWlJR3hsZEhSbGNpMXpjR0ZqYVc1blBTSXdMalpsYlNJK1BIUnpjR0Z1SUhnOUlqVTJJaUI1UFNJME1qZ2lQbEJQVjBWU1JVUWdRbGtnVmtWTlR6d3ZkSE53WVc0K1BDOTBaWGgwUGp4MFpYaDBJR1pwYkd3OUluZG9hWFJsSWlCNGJXdzZjM0JoWTJVOUluQnlaWE5sY25abElpQnpkSGxzWlQwaWQyaHBkR1V0YzNCaFkyVTZJSEJ5WlNJZ1ptOXVkQzFtWVcxcGJIazlJbFZ5WW1GdWFYTjBJaUJtYjI1MExYTnBlbVU5SWpJNElpQm1iMjUwTFhkbGFXZG9kRDBpTlRBd0lpQnNaWFIwWlhJdGMzQmhZMmx1WnowaU1HVnRJajQ4ZEhOd1lXNGdlRDBpTVRrMklpQjVQU0l5TmprdU9DSStUa1pVSUVGalkyOTFiblE4TDNSemNHRnVQand2ZEdWNGRENDhkR1Y0ZENCbWFXeHNQU0ozYUdsMFpTSWdlRzFzT25Od1lXTmxQU0p3Y21WelpYSjJaU0lnYzNSNWJHVTlJbmRvYVhSbExYTndZV05sT2lCd2NtVWlJR1p2Ym5RdFptRnRhV3g1UFNKVmNtSmhibWx6ZENJZ1ptOXVkQzF6YVhwbFBTSTBPQ0lnWm05dWRDMTNaV2xuYUhROUlqWXdNQ0lnYkdWMGRHVnlMWE53WVdOcGJtYzlJakJsYlNJK1BIUnpjR0Z1SUhnOUlqRTVOaUlnZVQwaU1qRXlMak1pUGxabGJXODhMM1J6Y0dGdVBqd3ZkR1Y0ZEQ0OGRHVjRkQ0JtYVd4c1BTSjNhR2wwWlNJZ2VHMXNPbk53WVdObFBTSndjbVZ6WlhKMlpTSWdjM1I1YkdVOUluZG9hWFJsTFhOd1lXTmxPaUJ3Y21VaUlHWnZiblF0Wm1GdGFXeDVQU0pWY21KaGJtbHpkQ0lnWm05dWRDMXphWHBsUFNJek1pSWdabTl1ZEMxM1pXbG5hSFE5SWpVd01DSWdiR1YwZEdWeUxYTndZV05wYm1jOUlqQmxiU0krUEhSemNHRnVJSGc5SWpVMklpQjVQU0k1T0M0eUlqNGpNVHd2ZEhOd1lXNCtQQzkwWlhoMFBqeDBaWGgwSUdacGJHdzlJbmRvYVhSbElpQm1hV3hzTFc5d1lXTnBkSGs5SWpBdU5pSWdlRzFzT25Od1lXTmxQU0p3Y21WelpYSjJaU0lnYzNSNWJHVTlJbmRvYVhSbExYTndZV05sT2lCd2NtVWlJR1p2Ym5RdFptRnRhV3g1UFNKVmNtSmhibWx6ZENJZ1ptOXVkQzF6YVhwbFBTSXlPQ0lnYkdWMGRHVnlMWE53WVdOcGJtYzlJakF1TURWbGJTSStQSFJ6Y0dGdUlIZzlJakU1TmlJZ2VUMGlNekUzTGpnaVBqQjROMlpoTGk0dU1UUTVOand2ZEhOd1lXNCtQQzkwWlhoMFBqeHdZWFJvSUdROUlrMDRPQzQyTmpBM0lESTNNaTQyTURaTU9EQXVOVEkxTXlBeU9EWXVPRE0wUXpjNUxqWXhNemNnTWpnNExqUXlPU0EzTnk0eU56WTRJREk0T0M0ek56Y2dOell1TkRNM05pQXlPRFl1TnpRMFREWXhMakV6TVRRZ01qVTJMamsyTkVNMk1DNDJNRGs1SURJMU5TNDVORGtnTmpFdU56TTJNaUF5TlRRdU9EZ3lJRFl5TGpjek5qa2dNalUxTGpRME1rdzROeTQzT0RNNUlESTJPUzQwTnpSRE9EZ3VPRGs1T0NBeU56QXVNRGs1SURnNUxqSTVNak1nTWpjeExqVXdNU0E0T0M0Mk5qQTNJREkzTWk0Mk1EWmFJaUJtYVd4c1BTSjNhR2wwWlNJdlBqeHdZWFJvSUdROUlrMHhNRE11T0RVMklESXhOQzR4TmpSTU5UVXVOelkyTlNBeU16a3VORFF6UXpVMExqQTBNaklnTWpRd0xqTTBPU0ExTVM0NU1ESTBJREl6T1M0Mk56VWdOVEV1TURJME9DQXlNemN1T1RRNFREUXdMak0zTmpFZ01qRTJMams1TjBNek9TNHlNVEVnTWpFMExqY3dOQ0EwTUM0NE9UTTRJREl4TWlBME15NDBPRFUxSURJeE1rd3hNRE11TXpFeUlESXhNa014TURRdU5USXhJREl4TWlBeE1EUXVPVEkwSURJeE15NDJNRElnTVRBekxqZzFOaUF5TVRRdU1UWTBXaUlnWm1sc2JEMGlkMmhwZEdVaUx6NDhjR0YwYUNCa1BTSk5NVEU1TGpVM015QXlNVFl1T1RBeFREa3lMalkyT1NBeU5qUXVOakF5UXpreUxqQTBNRGtnTWpZMUxqY3hOaUE1TUM0Mk1UY3lJREkyTmk0eE1TQTRPUzQwT1RjeElESTJOUzQwT0V3MU9DNHhNREl4SURJME55NDRNekZETlRZdU5UTTRNeUF5TkRZdU9UVXlJRFUyTGpVek5EY2dNalEwTGpjeU1pQTFPQzR3T1RVMklESTBNeTQ0TXpoTU1URXlMakkyTXlBeU1UTXVNVFU1UXpFeE15NDJNRFFnTWpFeUxqUWdNVEUxTGpFeU15QXlNVElnTVRFMkxqWTJPQ0F5TVRKRE1URTVMakl3T0NBeU1USWdNVEl3TGpneE1pQXlNVFF1TnpBMUlERXhPUzQxTnpNZ01qRTJMamt3TVZvaUlHWnBiR3c5SWlNd01EUTNSa1lpTHo0OFpHVm1jejQ4Y0dGMGRHVnliaUJwWkQwaWNHRjBkR1Z5YmpCZk9UY3dOMTgxTWpFMU5pSWdjR0YwZEdWeWJrTnZiblJsYm5SVmJtbDBjejBpYjJKcVpXTjBRbTkxYm1ScGJtZENiM2dpSUhkcFpIUm9QU0l4SWlCb1pXbG5hSFE5SWpFaVBqeDFjMlVnZUd4cGJtczZhSEpsWmowaUkybHRZV2RsTUY4NU56QTNYelV5TVRVMklpQjBjbUZ1YzJadmNtMDlJbk5qWVd4bEtEQXVNREF5SURBdU1EQXlNemMxTXlraUx6NDhMM0JoZEhSbGNtNCtQQzlrWldaelBqd3ZjM1puUGc9PSJ9", description),
            true
        );
        vm.stopPrank();
    }

}
