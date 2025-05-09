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


    function _mintTokens(address _to, uint256 _amount) internal {
        vm.startPrank(deployer);
        artTokenContract.mint(_to, _amount);
        artTokenContractUpgradeable.mint(_to, _amount);
        vm.stopPrank();
    }
}
