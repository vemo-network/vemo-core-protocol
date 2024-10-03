
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "multicall-authenticated/Multicall3.sol";
import "../../src/accounts/NFTAccountDelegable.sol";
import "../../src/AccountGuardian.sol";
import "../../src/accounts/AccountProxy.sol";
import {CollectionDeployer} from "../../src/CollectionDeployer.sol";
import {VemoDelegationCollection} from "../../src/helpers/VemoDelegationCollection.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "erc6551/ERC6551Registry.sol";
import "../accounts/executable/mocks/MockERC721.sol";
import "../accounts/executable/mocks/MockAccountUpgradable.sol";
import {WalletFactory} from "../../src/WalletFactory.sol";
import {NFTDelegationDescriptor} from "../../src/helpers/NFTDescriptor/DelegationURI/NFTDelegationDescriptor.sol";
import {NFTAccountDescriptor} from "../../src/helpers/NFTDescriptor/NFTAccount/NFTAccountDescriptor.sol";
import {VePendleTerm} from "../../src/terms/VePendleTerm.sol";

interface ISwapRouter {
    function exactInputSingle(
        ISwapRouter.ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
}

interface IVePendle is IERC20 {
    function increaseLockPositionAndBroadcast(uint128 additionalAmountToLock, uint128 newExpiry, uint256[] memory chains) external returns (uint128 newVeBalance);
    function increaseLockPosition(uint128 additionalAmountToLock, uint128 newExpiry) external returns (uint128 newVeBalance);
    function withdraw() external returns (uint128 amount);
}

struct VeBalance {
    uint128 bias;
    uint128 slope;
}

struct UserPoolData {
    uint64 weight;
    VeBalance vote;
}
interface IPendleVoting {
    function vote(address[] memory pools, uint64[] memory weights) external; // total weights  = 1e18
    function getUserPoolVote(address user, address pool) external view returns (UserPoolData memory);
}

interface IPendleGaugeController {
}

interface IPendleRewardManager {
    function claimRetail(
        address receiver,
        uint256 totalAccrued,
        bytes32[] calldata proof
    ) external returns (uint256 amountOut);
}


interface IWETH9 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

contract PendleFlowTest is Test {
    bytes32 salt = bytes32(0x12341e82a3386d28036d6f63d1e6efd90031d3e8a56e75da9f0b021f40b0bc4c);

    Multicall3 forwarder = Multicall3(0x560123E26A057A3e1006d17091a0e82855Ec52b8);
    IERC20 PENDLE = IERC20(0x808507121B80c02388fAd14726482e061B8da827);
    IVePendle VE_PENDLE = IVePendle(0x4f30A9D41B80ecC5B94306AB4364951AE3170210);
    ISwapRouter constant UNISWAP_V3_ROUTER = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IWETH9 WETH = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address signer;
    uint256 signerpvk = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    IPendleVoting constant PENDLE_VOTING = IPendleVoting(0x44087E105137a5095c008AaB6a6530182821F2F0);
    IPendleGaugeController constant GAUGE_CONTROLLER = IPendleGaugeController(0x47D74516B33eD5D70ddE7119A40839f6Fcc24e57);
    IPendleRewardManager constant REWARD_MANAGER = IPendleRewardManager(0x8C237520a8E14D658170A633D96F8e80764433b9);
    
    //// Vemo setup
    NFTAccountDelegable upgradableImplementation;
    AccountProxy proxy;
    ERC6551Registry public registry;
    AccountGuardian public guardian;
    WalletFactory walletFactory;

    address defaultAdmin = vm.addr(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d);
    NFTDelegationDescriptor delegationDescriptor;
    NFTAccountDescriptor vemoCollectionDescriptor;
    VePendleTerm term;

    CollectionDeployer collectionDeployer = CollectionDeployer(0x84F27Ab1722BCA7D0B0D9944E2ADFB451Baeb0a9);
    
    address globalTba;
    address NFTAccountCollection;
    address dlgCollection;

    uint256 constant PROPOSAL_ID = 1;
    address constant GAUGE_ADDRESS = 0xC374f7eC85F8C7DE3207a10bB1978bA104bdA3B2;

    bool public isForkEnabled;
    function setUp() public {
        isForkEnabled = vm.envOr("LOCAL_FORK_ENABLED", false);

        if (isForkEnabled) {
            vm.createSelectFork("http://127.0.0.1:8545");
            signer = vm.addr(signerpvk);
            deployVemoSystem();
            (,globalTba) = deployTbaAndDelegate();

            vm.startPrank(signer);

            uint256 ethAmount = 100 ether;

            vm.deal(signer, 200 ether);
            vm.deal(defaultAdmin, 100 ether);

            IWETH9(WETH).deposit{value: ethAmount}();
            IWETH9(WETH).approve(address(UNISWAP_V3_ROUTER), ethAmount);

            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: address(WETH),
                tokenOut: address(PENDLE),
                fee: 3000,
                recipient: signer,
                deadline: block.timestamp + 15 minutes,
                amountIn: ethAmount, 
                amountOutMinimum: 0, 
                sqrtPriceLimitX96: 0
            });

            uint256 amountOut = UNISWAP_V3_ROUTER.exactInputSingle(params);
            
            PENDLE.transfer(globalTba, amountOut/2);

            vm.stopPrank();

            stakePendleToVePendle(globalTba);
        }
    }

    modifier onlyEnableFork() {
        if (!isForkEnabled) {
            return;
        }
        _;
    }

    function deployTbaAndDelegate() public returns (uint256 _id, address _tba_) {
        vm.startPrank(defaultAdmin);
        (_id, _tba_) = walletFactory.create(NFTAccountCollection);

        NFTAccountDelegable(payable(_tba_)).delegate(dlgCollection, defaultAdmin);
    }

    function deployVemoSystem() public {
        vm.startPrank(defaultAdmin);
        registry = new ERC6551Registry{salt: salt}();
        forwarder = new Multicall3{salt: salt}();
        guardian = new AccountGuardian{salt: salt}(defaultAdmin);
        upgradableImplementation = new NFTAccountDelegable{salt: salt}(
            address(forwarder), address(registry), address(guardian)
        );
        proxy = new AccountProxy{salt: salt}(address(guardian), address(upgradableImplementation));

        guardian.setTrustedImplementation(address(upgradableImplementation), true);

        address walletProxy = Upgrades.deployUUPSProxy(
            "WalletFactory.sol:WalletFactory",
            abi.encodeCall(
                WalletFactory.initialize,
                (defaultAdmin, address(registry), address(upgradableImplementation), address(upgradableImplementation))
            )
        );

        walletFactory = WalletFactory(payable(walletProxy));

        delegationDescriptor = NFTDelegationDescriptor(Upgrades.deployUUPSProxy(
            "NFTDelegationDescriptor.sol:NFTDelegationDescriptor",
            abi.encodeCall(
                NFTDelegationDescriptor.initialize,
                (defaultAdmin)
            )
        ));

        vemoCollectionDescriptor = NFTAccountDescriptor(Upgrades.deployUUPSProxy(
            "NFTAccountDescriptor.sol:NFTAccountDescriptor",
            abi.encodeCall(
                NFTAccountDescriptor.initialize,
                (defaultAdmin)
            )
        ));

        term = VePendleTerm(payable(Upgrades.deployUUPSProxy(
            "VePendleTerm.sol:VePendleTerm",
            abi.encodeCall(
                VePendleTerm.initialize,
                (
                    defaultAdmin,
                    walletProxy,
                    address(guardian)
                )
            )
        )));

        collectionDeployer = new CollectionDeployer{salt: salt}(walletProxy);
        walletFactory.setCollectionDeployer(address(collectionDeployer));

        NFTAccountCollection = walletFactory.createWalletCollection(
            1,
            "walletfactory1",
            "walletfactory1",
            address(vemoCollectionDescriptor)
        );
        
        // create delegate collection
        dlgCollection = walletFactory.createDelegateCollection(
            "A",
            "A1",
            address(delegationDescriptor), 
            address(term),
            NFTAccountCollection
        );
    }

     function stakePendleToVePendle(address _tba_) public {
        vm.startPrank(defaultAdmin);

        if (_tba_ == address(0)) {
            _tba_ = _tba_;
        }

        // uint256 additionalAmountToLock = 100 * 1e18; // 10 PENDLE tokens
        uint256 additionalAmountToLock = PENDLE.balanceOf(_tba_);
        uint128 newExpiry = 1788998400; 
        
        // Approve PENDLE spending for vePENDLE
        bytes memory approveCalldata = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(VE_PENDLE),
            additionalAmountToLock
        );

        NFTAccountDelegable(payable(_tba_)).execute(address(PENDLE), 0, approveCalldata, 0);

        // Increase lock position using TBA
        bytes memory increaseLockCalldata = abi.encodeWithSignature(
            "increaseLockPosition(uint128,uint128)",
            additionalAmountToLock,
            newExpiry
        );
        NFTAccountDelegable(payable(_tba_)).execute(address(VE_PENDLE), 0, increaseLockCalldata, 0);

        (,, uint256 tokenId) = NFTAccountDelegable(payable(_tba_)).token();

        // using the delegation to vote
        VemoDelegationCollection(dlgCollection).transferFrom(defaultAdmin, signer, tokenId);
        
        vm.startPrank(signer);
        vm.deal(_tba_, 0.1 ether);
        NFTAccountDelegable(payable(_tba_)).delegateExecute(dlgCollection, signer, 0.1 ether, "", "");
        assertEq(_tba_.balance, 0);
    }

    function testVoteOnProposal() public onlyEnableFork {
        vm.startPrank(signer);

        assertTrue(
            VE_PENDLE.balanceOf(globalTba) > 0, ""
        );

        // Check initial voting status
        UserPoolData memory preVote = PENDLE_VOTING.getUserPoolVote(GAUGE_ADDRESS, globalTba);
        assertTrue(preVote.weight == 0, "Should not have voted initially");


        address[] memory pools = new address[](1);
        pools[0] = GAUGE_ADDRESS;

        uint64[] memory weights = new uint64[](1);
        weights[0] = 1e18;

        // Approve PENDLE spending for vePENDLE
        bytes memory voteCalldata = abi.encodeWithSignature(
            "vote(address[],uint64[])",
            pools,
            weights
        );

        NFTAccountDelegable(payable(globalTba)).delegateExecute(dlgCollection, address(PENDLE_VOTING), 0, voteCalldata, "");

        preVote = PENDLE_VOTING.getUserPoolVote(GAUGE_ADDRESS, globalTba);
        assertGe(preVote.weight, 0);
    }

    function testLimitJustVoteOnProposal() public onlyEnableFork {
        vm.startPrank(defaultAdmin);
        address[] memory whitelist = new address[](1);
        whitelist[0] = address(UNISWAP_V3_ROUTER);
        
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = ISwapRouter.exactInputSingle.selector;
        bytes4[] memory _harvestSelectors;
        address[] memory _whitelist;
        address[] memory _rewardAssets_ = new address[](1);
        _rewardAssets_[0] = address(0);
        
        term.setTermProperties(address(0), selectors, _harvestSelectors, whitelist, _rewardAssets_ );

        vm.startPrank(signer);
        // Check initial voting status
        UserPoolData memory preVote = PENDLE_VOTING.getUserPoolVote(GAUGE_ADDRESS, globalTba);
        assertTrue(preVote.weight == 0, "Should not have voted initially");

        address[] memory pools = new address[](1);
        pools[0] = GAUGE_ADDRESS;

        uint64[] memory weights = new uint64[](1);
        weights[0] = 1e18;

        bytes memory voteCalldata = abi.encodeWithSignature(
            "vote(address[],uint64[])",
            pools,
            weights
        );
        vm.expectRevert();
        NFTAccountDelegable(payable(globalTba)).delegateExecute(dlgCollection, address(PENDLE_VOTING), 0, voteCalldata, "");

        // allow voting
        selectors[0] = PENDLE_VOTING.vote.selector;
        whitelist[0] = address(PENDLE_VOTING);
        vm.startPrank(defaultAdmin);
        term.setTermProperties(address(0), selectors, _harvestSelectors, whitelist, _rewardAssets_ );

        vm.startPrank(signer);
        NFTAccountDelegable(payable(globalTba)).delegateExecute(dlgCollection, address(PENDLE_VOTING), 0, voteCalldata, "");

        // allow harvesting 
        vm.startPrank(defaultAdmin);
        whitelist = new address[](2);
        selectors = new bytes4[](2);
        _harvestSelectors = new bytes4[](1);
        
        selectors[0] = PENDLE_VOTING.vote.selector;
        selectors[1] = IPendleRewardManager.claimRetail.selector;
        _harvestSelectors[0] = IPendleRewardManager.claimRetail.selector;

        whitelist[0] = address(PENDLE_VOTING);
        whitelist[1] = address(REWARD_MANAGER);
        term.setTermProperties(address(0), selectors, _harvestSelectors, whitelist, _whitelist );

        // calling harvest
        vm.startPrank(signer);
        NFTAccountDelegable(payable(globalTba)).delegateExecute(dlgCollection, address(PENDLE_VOTING), 0, voteCalldata, "");

        bytes32[] memory proof;
        bytes memory claimCalldata = abi.encodeWithSignature(
            "claimRetail(address,uint256,bytes32[])",
            signer,
            0.001 ether,
            proof
        );
        term.canExecute(address(REWARD_MANAGER), 0, claimCalldata);
        // NFTAccountDelegable(payable(_tba)).delegateExecute(dlgCollection, address(REWARD_MANAGER), 0, claimCalldata, "");
    }

    function testBatchVote() public {
        uint256 batch_number = 20;
        address[] memory tbas_100 = new address[](batch_number);
        for (uint i = 0; i < batch_number; i++) {
            (, address _tba_) = deployTbaAndDelegate();
            tbas_100[i] = _tba_;
            deal(address(PENDLE), _tba_, 10 ether);
            stakePendleToVePendle(_tba_);
        }

        // estimate gas for vote
        address[] memory pools = new address[](1);
        pools[0] = GAUGE_ADDRESS;

        uint64[] memory weights = new uint64[](1);
        weights[0] = 1e18;

        bytes memory voteCalldata = abi.encodeWithSignature(
            "vote(address[],uint64[])",
            pools,
            weights
        );
        
        uint gas = gasleft();
        for (uint i = 0; i < batch_number; i++) {
            NFTAccountDelegable(payable(tbas_100[i])).delegateExecute(dlgCollection, address(PENDLE_VOTING), 0, voteCalldata, "");
        }

        uint gasAfterVote = gas - gasleft();
        console.log("vote %s tba costing %s", batch_number, gasAfterVote);
        
        // try with multicall
        Multicall3.Call3[] memory calls = new Multicall3.Call3[](batch_number);
        for (uint i = 0; i < batch_number; i++) {
            calls[i] = Multicall3.Call3(
                tbas_100[i],
                false,
                abi.encodeWithSignature(
                    "delegateExecute(address,address,uint256,bytes,bytes)",
                    dlgCollection,
                    address(PENDLE_VOTING),
                    0,
                    voteCalldata,
                    ""
                )
            );
        }
        gas = gasleft();
        Multicall3.Result[] memory results = forwarder.aggregate3(calls);
        
        gasAfterVote = gas - gasleft();
        console.log("vote %s tba multicall costing %s", batch_number, gasAfterVote);

        for (uint256 i = 0; i < results.length; i++) {
          assertTrue(results[i].success);
          assertEq(results[i].returnData, abi.encode(new bytes(0)));
        }
    }
}