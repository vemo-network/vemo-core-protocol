pragma solidity >=0.4.16;

library DateTime {
    /*
     *  Date and Time utilities for ethereum contracts
     *
     */
    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
    }

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

    function parseTimestamp(
        uint timestamp
    ) internal pure returns (_DateTime memory dt) {
        uint256 SECONDS_PER_DAY = 24 * 60 * 60;
        uint256 SECONDS_PER_HOUR = 60 * 60;
        uint256 SECONDS_PER_MINUTE = 60;

        uint256 OFFSET19700101 = 2440588;

        // Number of days passed since Unix epoch
        uint256 _days = timestamp / SECONDS_PER_DAY;

        // Time parts
        uint256 remainder = timestamp % SECONDS_PER_DAY;
        uint8 hour = uint8(remainder / SECONDS_PER_HOUR);
        remainder = remainder % SECONDS_PER_HOUR;
        uint8 minute = uint8(remainder / SECONDS_PER_MINUTE);
        uint8 second = uint8(remainder % SECONDS_PER_MINUTE);

        // Date parts
        uint256 L = _days + 68569 + OFFSET19700101;
        uint256 N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        uint256 _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        uint256 _month = 80 * L / 2447;
        uint256 _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        return _DateTime({
            year: uint16(_year),
            month: uint8(_month),
            day: uint8(_day),
            hour: hour,
            minute: minute,
            second: second
        });
    }


    function padZero(uint8 number) internal pure returns (string memory) {
        if (number < 10) {
            return string(abi.encodePacked("0", uintToStr(number)));
        }
        return uintToStr(number);
    }

    function uintToStr(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function formatDateTime(_DateTime memory dt) internal pure returns (string memory) {
        string memory month = padZero(dt.month);
        string memory day = padZero(dt.day);
        string memory year = uintToStr(dt.year);
        string memory hour = padZero(dt.hour);
        string memory minute = padZero(dt.minute);
        string memory second = padZero(dt.second);

        return string(abi.encodePacked(month, "/", day, "/", year, " ", hour, ":", minute, ":", second, " UTC"));
    }
}
