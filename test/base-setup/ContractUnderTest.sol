// SPDX-License-Identifier: MIT UNLICENSED
pragma solidity 0.8.26;

import {ArtToken} from "contracts/ArtToken.sol";
import {ArtTokenUpgradeable} from "contracts/ArtTokenUpgradeable.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "forge-std/Test.sol";

abstract contract ContractUnderTest is Test {
    uint256 public mainnetFork;
    ArtToken internal artTokenContract;
    ArtTokenUpgradeable internal artTokenContractUpgradeable;

    // Contract deployment details
    string name = "ArtToken";
    string symbol = "ART";
    address lzEndpoint =  0x1a44076050125825900e736c501f859c50fE728c; // base mainnet

    // Users
    address payable deployer = payable(makeAddr("deployer"));
    address payable user1 = payable(makeAddr("user1"));
    address payable user2 = payable(makeAddr("user2"));
    address payable unauthorizedUser = payable(makeAddr("unauthorizedUser"));
    address payable claimer1 = payable(makeAddr("claimer1"));
    address payable claimer2 = payable(makeAddr("claimer2"));
    address public proxyAdmin = makeAddr("proxyAdmin");

    // Constants
    uint256 public CLAIM_AMOUNT = 1000 * 10 ** 18;
    uint256 public INITIAL_MINT_AMOUNT = 1_000_000;


    function setUp() public virtual {
        // Mainnet fork
        string memory mainnet_rpc_url_key = "ALCHEMY_URL";
        string memory mainnet_rpc_url = vm.envString(mainnet_rpc_url_key);
        mainnetFork = vm.createFork(mainnet_rpc_url);

        vm.startPrank(deployer);
        _deployNonUpgradeableContract();
        _deployUpgradeableContract();
        vm.stopPrank();
    }


    function _deployNonUpgradeableContract() internal {
        artTokenContract = new ArtToken(name, symbol, lzEndpoint, deployer, INITIAL_MINT_AMOUNT);
        vm.label({account: address(artTokenContract), newLabel: "ArtToken"});

        artTokenContract.setClaimableSupply(CLAIM_AMOUNT * 3);
    }

    function _deployUpgradeableContract() internal {
          artTokenContractUpgradeable = ArtTokenUpgradeable(
            _deployContractAndProxy(
                type(ArtTokenUpgradeable).creationCode,
                abi.encode(lzEndpoint),
                abi.encodeWithSelector(
                    ArtTokenUpgradeable.initialize.selector,
                    "ArtTokenUpgradeable",
                    "ART_UPGRADEABLE",
                    deployer,
                    INITIAL_MINT_AMOUNT
                )
            )
        );

        vm.label({account: address(artTokenContractUpgradeable), newLabel: "ArtTokenUpgradeable"});

        artTokenContractUpgradeable.setClaimableSupply(CLAIM_AMOUNT * 3);
    }


    function _deployContractAndProxy(
        bytes memory _oappBytecode,
        bytes memory _constructorArgs,
        bytes memory _initializeArgs
    ) internal returns (address addr) {
        bytes memory bytecode = bytes.concat(abi.encodePacked(_oappBytecode), _constructorArgs);
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        return address(new TransparentUpgradeableProxy(addr, proxyAdmin, _initializeArgs));
    }

    function _claimerDetails()
        internal
        returns (bytes32 merkleRoot, bytes32[] memory merkleProof)
    {
        // Create merkle tree with two addresses
        bytes32[] memory leaves = new bytes32[](2);
        leaves[0] = keccak256(abi.encodePacked(claimer1, CLAIM_AMOUNT));
        leaves[1] = keccak256(abi.encodePacked(claimer2, CLAIM_AMOUNT * 2));

        // Sort leaves for consistent merkle tree
        if (uint256(leaves[0]) > uint256(leaves[1])) {
            bytes32 temp = leaves[0];
            leaves[0] = leaves[1];
            leaves[1] = temp;
        }

        // Calculate merkle root
        merkleRoot = keccak256(abi.encodePacked(leaves[0], leaves[1]));

        // Generate proof for claimer1
        merkleProof = new bytes32[](1);
        merkleProof[0] = leaves[1];

        vm.startPrank(deployer);
        artTokenContract.setMerkleRoot(merkleRoot);
        artTokenContractUpgradeable.setMerkleRoot(merkleRoot);
        vm.stopPrank();
    }

    function _setStakingContract(address _stakingContract) internal {
        vm.startPrank(deployer);
        artTokenContract.setStakingContractAddress(_stakingContract);
        artTokenContractUpgradeable.setStakingContractAddress(_stakingContract);
        vm.stopPrank();
    }

    function _setClaimableSupply(uint256 _amount) internal {
        vm.startPrank(deployer);
        artTokenContract.setClaimableSupply(_amount);
        artTokenContractUpgradeable.setClaimableSupply(_amount);
        vm.stopPrank();
    }

    function _setVestingStartTime(uint256 _time) internal {
        vm.startPrank(deployer);
        artTokenContract.setVestingStartTime(_time);
        artTokenContractUpgradeable.setVestingStartTime(_time);
        vm.stopPrank();
    }

    function _mintTokens(address _to, uint256 _amount) internal {
        vm.startPrank(deployer);
        artTokenContract.mint(_to, _amount);
        artTokenContractUpgradeable.mint(_to, _amount);
        vm.stopPrank();
    }

    function _formatToE18(uint256 _percentage) internal pure returns (uint256) {
        return (_percentage * 1e18) / 100;
    }
}
