// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IFactory.sol";
import "./interfaces/IDynamic.sol";
import "./interfaces/IComposable.sol";
import "./interfaces/IDerivable.sol";
import "./interfaces/IInscriptable.sol";
import "./helpers/DataStruct.sol";

contract DataRegistryV2 is
    IDynamic,
    IComposable,
    IDerivable,
    AccessControlUpgradeable,
    ERC721Upgradeable,
    IERC721Receiver,
    IERC2981
{
    /**
     * @dev The registry MUST emit the URIUpdated event upon update dapp-uri successfully
     */
    event URIUpdated(string uri);

    /**
     * @dev The registry MUST emit the WriteBatch event upon write batch successfully
     */
    event WriteBatch(address collection, uint256 startId, uint256 endId, bytes32 key, bytes value);

    using Address for address;

    // constants
    bytes32 public constant WRITER_ROLE = keccak256("WRITER_ROLE");
    string private constant REGISTRY_NAME = "NFT2.0 Registry";
    string private constant REGISTRY_SYMBOL = "NFT2.0";
    bytes private constant EMPTY_VALUE = "";

    address private _factory;
    address public dapp;
    string public uri;
    uint256 private _nextTokenId;
    bool public disableComposable;
    bool public disableDerivable;

    // data scheme v2 - supported for write-batch
    mapping(
        bytes32 key => mapping(address collection => mapping(uint256 highId => mapping(uint256 lowId => bytes value)))
    ) private _datas;
    mapping(bytes32 key => mapping(address collection => mapping(uint256 highId => uint256 lowId))) private _ranges;
    mapping(bytes32 key => mapping(address collection => uint256 topId)) _tips;
    mapping(bytes32 key => mapping(address collection => mapping(uint256 currentId => uint256 nextId))) private _nodes;

    // derived NFT
    mapping(address underlyingCollection => mapping(uint256 underlyingTokenId => DerivedToken derivedToken)) private
        _derivatives;
    mapping(uint256 tokenId => Token underlying) private _underlyings;
    mapping(uint256 tokenId => address derivedAccount) private _derivedAccounts;
    mapping(uint256 tokenId => uint256 royaltyRate) private _royaltyRates;

    modifier onComposable() {
        require(!disableComposable, "Composable MUST be enable");
        _;
    }

    modifier onDerivable() {
        require(!disableDerivable, "Derivable MUST be enable");
        _;
    }

    function initialize(address _dapp, address factory, string calldata _uri, DataRegistrySettings calldata settings)
        external
        initializer
    {
        ERC721Upgradeable.__ERC721_init(REGISTRY_NAME, REGISTRY_SYMBOL);

        _factory = factory;
        dapp = _dapp;
        uri = _uri;
        _nextTokenId = 1;
        disableComposable = settings.disableComposable;
        disableDerivable = settings.disableDerivable;

        _grantRole(DEFAULT_ADMIN_ROLE, _dapp);
        _grantRole(WRITER_ROLE, _dapp);
    }

    function updateUri(string calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uri = _uri;
        emit URIUpdated(_uri);
    }

    // ====================================================
    //                    ERC721Receiver
    // ====================================================
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        public
        pure
        override
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    // ====================================================
    //                    ERC2981
    // ====================================================
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_underlyings[tokenId].collection != address(0), "Derived token MUST be valid");

        royaltyAmount = (salePrice * _royaltyRates[tokenId]) / _feeDenominator();
        return (
            IFactory(_factory).derivedAccountOf(_underlyings[tokenId].collection, _underlyings[tokenId].tokenId),
            royaltyAmount
        );
    }

    // royalty denominator in terms of basis point
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    // ====================================================
    //                    DYNAMIC
    // ====================================================
    function writeBatch(address collection, uint256 startId, uint256 endId, bytes32 key, bytes calldata value)
        public
        onlyRole(WRITER_ROLE)
    {
        require(startId <= endId, "Start and End MUST be proper");

        if (startId == 0) {
            require(
                _tips[key][collection] == 0 && _datas[key][collection][0][0].length == 0, "Range MUST not be overlapped"
            );
        } else {
            require(startId > _tips[key][collection], "Range MUST not be overlapped");
        }

        _writeBatch(collection, startId, endId, key, value);
        _ranges[key][collection][endId] = startId;
        _insertNodes(key, collection, endId);
    }

    function write(address collection, uint256 tokenId, bytes32 key, bytes calldata value)
        public
        onlyRole(WRITER_ROLE)
    {
        _writeSafe(collection, tokenId, key, value);
    }

    function _writeSafe(address collection, uint256 tokenId, bytes32 key, bytes calldata value) private {
        require(_isUsable(collection, tokenId), "Token MUST be usable at the moment");

        if (collection == address(this)) {
            return _writeDerived(tokenId, key, value);
        }

        return _write(collection, tokenId, key, value);
    }

    function writeBatchForSingleNFT(
        address collection,
        uint256 tokenId,
        bytes32[] calldata keys,
        bytes[] calldata values
    ) public onlyRole(WRITER_ROLE) {
        _writeSafeBatchForSingleNFT(collection, tokenId, keys, values);
    }

    function _writeSafeBatchForSingleNFT(
        address collection,
        uint256 tokenId,
        bytes32[] calldata keys,
        bytes[] calldata values
    ) private {
        require(keys.length == values.length, "Keys and values MUST be same length arrays");
        require(_isUsable(collection, tokenId), "Token MUST be usable at the moment");

        uint8 j;
        while (j < keys.length) {
            if (collection == address(this)) {
                _writeDerived(tokenId, keys[j], values[j]);
            } else {
                _write(collection, tokenId, keys[j], values[j]);
            }
            j++;
        }
    }

    function _writeDerived(uint256 tokenId, bytes32 key, bytes memory value) private {
        Token memory underlying = _underlyings[tokenId];

        _write(underlying.collection, underlying.tokenId, key, value);
    }

    function _write(address collection, uint256 tokenId, bytes32 key, bytes memory value) private {
        (bool isFound, TokenRange memory range) = _findRange(key, collection, tokenId, _tips[key][collection]);

        if (!isFound) {
            _writeBatch(collection, tokenId, tokenId, key, value);
            _ranges[key][collection][tokenId] = tokenId;
            if (tokenId > _tips[key][collection]) {
                _nodes[key][collection][tokenId] = _tips[key][collection];
                _tips[key][collection] = tokenId;
            } else if (tokenId == _tips[key][collection]) {
                return;
            } else if (tokenId < range.end && tokenId > range.start) {
                _nodes[key][collection][range.end] = tokenId;
                _nodes[key][collection][tokenId] = range.start;
            }
        } else {
            if (range.end == range.start) {
                _writeBatch(collection, tokenId, tokenId, key, value);
            } else {
                bytes memory currentValue = _datas[key][collection][range.end][range.start];
                uint256 next = _nodes[key][collection][range.end];

                _writeBatch(collection, tokenId, tokenId, key, value);
                _ranges[key][collection][tokenId] = tokenId;
                if (tokenId > range.start) {
                    _nodes[key][collection][tokenId] = tokenId - 1;

                    _writeBatch(collection, range.start, tokenId - 1, key, currentValue);
                    _ranges[key][collection][tokenId - 1] = range.start;
                    _nodes[key][collection][tokenId - 1] = next;
                }

                if (tokenId < range.end) {
                    _writeBatch(collection, tokenId + 1, range.end, key, currentValue);
                    _ranges[key][collection][range.end] = tokenId + 1;
                    _nodes[key][collection][range.end] = tokenId;
                }
            }
        }
    }

    function read(address collection, uint256 tokenId, bytes32 key) public view returns (bytes memory value) {
        require(_isUsable(collection, tokenId), "Token MUST be usable at the moment");

        if (collection == address(this)) {
            Token memory underlying = _underlyings[tokenId];
            return _read(underlying.collection, underlying.tokenId, key);
        }
        return _read(collection, tokenId, key);
    }

    function _read(address collection, uint256 tokenId, bytes32 key) private view returns (bytes memory value) {
        (bool isFound, TokenRange memory range) = _findRange(key, collection, tokenId, _tips[key][collection]);
        require(isFound, "Range data is not found");

        return _datas[key][collection][range.end][range.start];
    }

    function _writeBatch(address collection, uint256 startId, uint256 endId, bytes32 key, bytes memory value) private {
        _datas[key][collection][endId][startId] = value;

        // emit events
        emit WriteBatch(collection, startId, endId, key, value);
    }

    function _insertNodes(bytes32 key, address collection, uint256 tokenId) private {
        if (tokenId > _tips[key][collection]) {
            _nodes[key][collection][tokenId] = _tips[key][collection];
            _tips[key][collection] = tokenId;
        } else if (tokenId == _tips[key][collection]) {
            return;
        } else {
            uint256 current = _tips[key][collection];
            while (tokenId < _nodes[key][collection][current]) {
                current = _nodes[key][collection][current];
            }

            if (tokenId > _nodes[key][collection][current]) {
                _nodes[key][collection][tokenId] = _nodes[key][collection][current];
                _nodes[key][collection][current] = tokenId;
            }
        }
    }

    function _findRange(bytes32 key, address collection, uint256 tokenId, uint256 top)
        private
        view
        returns (bool isFound, TokenRange memory)
    {
        if (tokenId > top) {
            return (false, TokenRange(top, tokenId));
        } else if (tokenId >= _ranges[key][collection][top]) {
            if (_datas[key][collection][top][_ranges[key][collection][top]].length > 0) {
                return (true, TokenRange(_ranges[key][collection][top], top));
            } else {
                return (false, TokenRange(_nodes[key][collection][top], top));
            }
        } else if (tokenId > _nodes[key][collection][top]) {
            return (false, TokenRange(_nodes[key][collection][top], top));
        } else {
            return _findRange(key, collection, tokenId, _nodes[key][collection][top]);
        }
    }

    // ====================================================
    //                    COMPOSABLE
    // ====================================================
    function compose(Token calldata srcToken, Token calldata descToken, bytes32[] calldata keyNames)
        public
        onComposable
        returns (bool)
    {
        require(
            IERC721(srcToken.collection).ownerOf(srcToken.tokenId) == _msgSender(),
            "Sender MUST be owner of source token"
        );
        require(
            IERC721(descToken.collection).ownerOf(descToken.tokenId) == _msgSender(),
            "Sender MUST be owner of destination token"
        );
        require(
            srcToken.collection != address(this) && descToken.collection != address(this),
            "Derived token SHALL NOT be composable"
        );

        uint256 j;
        while (j < keyNames.length) {
            _write(
                descToken.collection,
                descToken.tokenId,
                keyNames[j],
                _read(srcToken.collection, srcToken.tokenId, keyNames[j])
            );
            _write(srcToken.collection, srcToken.tokenId, keyNames[j], EMPTY_VALUE);
            j++;
        }

        emit Compose(srcToken.collection, srcToken.tokenId, descToken.collection, descToken.tokenId, keyNames);
        return true;
    }

    // ====================================================
    //                    DERIVABLE
    // ====================================================
    function derive(
        address underlyingCollection,
        uint256 underlyingTokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 royaltyRate
    ) public onDerivable returns (bool) {
        require(
            IERC721(underlyingCollection).ownerOf(underlyingTokenId) == _msgSender(),
            "Sender MUST be owner of underlying token"
        );
        require(_isDerivable(underlyingCollection, underlyingTokenId), "Underlying token SHALL NOT derivable");
        require(startTime < endTime, "Start time MUST be before End time");
        require(royaltyRate <= _feeDenominator(), "The royalty rate MUST NOT exceed limit percentage");

        address derivedAccount = IFactory(_factory).createDerivedAccount(underlyingCollection, underlyingTokenId);

        uint256 tokenId = _nextTokenId++;
        _safeMint(_msgSender(), tokenId);

        _derivatives[underlyingCollection][underlyingTokenId] = DerivedToken(address(this), tokenId, startTime, endTime);
        _underlyings[tokenId] = Token(underlyingCollection, underlyingTokenId);
        _derivedAccounts[tokenId] = derivedAccount;
        _royaltyRates[tokenId] = royaltyRate;

        emit Derive(underlyingCollection, underlyingTokenId, address(this), tokenId, startTime, endTime);

        return false;
    }

    function reclaim(address underlyingCollection, uint256 underlyingTokenId) public onDerivable returns (bool) {
        require(_isReclaimable(_msgSender(), underlyingCollection, underlyingTokenId), "Token is not reclaimable");

        DerivedToken memory derived = _derivatives[underlyingCollection][underlyingTokenId];
        _burn(derived.tokenId);

        delete _derivatives[underlyingCollection][underlyingTokenId];
        delete _underlyings[derived.tokenId];

        emit Reclaim(underlyingCollection, underlyingTokenId, derived.collection, derived.tokenId);

        return false;
    }

    function isDerivable(address collection, uint256 tokenId) public view onDerivable returns (bool) {
        return _isDerivable(collection, tokenId);
    }

    function isUsable(address collection, uint256 tokenId) public view onDerivable returns (bool) {
        return _isUsable(collection, tokenId);
    }

    function isReclaimable(address requester, address collection, uint256 tokenId)
        public
        view
        onDerivable
        returns (bool)
    {
        return _isReclaimable(requester, collection, tokenId);
    }

    function _isDerivable(address underlyingCollection, uint256 underlyingTokenId) private view returns (bool) {
        DerivedToken memory derived = _derivatives[underlyingCollection][underlyingTokenId];
        if (derived.collection == address(0)) {
            return true;
        }

        return false;
    }

    function _isUsable(address collection, uint256 tokenId) private view returns (bool) {
        if (collection == address(this)) {
            // derived token
            Token memory underlying = _underlyings[tokenId];
            uint256 startTime = _derivatives[underlying.collection][underlying.tokenId].startTime;
            uint256 endTime = _derivatives[underlying.collection][underlying.tokenId].endTime;
            if (block.timestamp >= startTime && block.timestamp <= endTime) return true;
            return false;
        }

        DerivedToken memory derived = _derivatives[collection][tokenId];
        if (derived.collection == address(0)) return true;
        if (block.timestamp >= derived.startTime && block.timestamp <= derived.endTime) return false;
        return true;
    }

    function _isReclaimable(address requester, address collection, uint256 tokenId) private view returns (bool) {
        require(IERC721(collection).ownerOf(tokenId) == requester, "Requester MUST be owner of token");
        require(collection != address(this), "Claimed token MUST be underlying");
        DerivedToken memory derived = _derivatives[collection][tokenId];
        require(derived.collection != address(0), "Claimed token MUST has derived");

        // if requester has also been owner of derived token then legitimate
        if (ownerOf(derived.tokenId) == requester) return true;

        // only claimable after derived time ends
        if (block.timestamp > derived.endTime) return true;

        return false;
    }

    function derivedOf(address underlyingCollection, uint256 underlyingTokenId)
        public
        view
        onDerivable
        returns (DerivedToken memory)
    {
        return _derivatives[underlyingCollection][underlyingTokenId];
    }

    function underlyingOf(uint256 derivedTokenId) public view onDerivable returns (address, uint256) {
        return (_underlyings[derivedTokenId].collection, _underlyings[derivedTokenId].tokenId);
    }

    // ====================================================
    //                    IERC165
    // ====================================================
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || interfaceId == 0x2a55205a // IERC2981
            || interfaceId == 0xd212301b // IDynamic
            || interfaceId == 0x17e6e974 // IComposable
            || interfaceId == 0xd63e236c; // IDerivable
    }
}
