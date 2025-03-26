// SPDX-License-Identifier: MIT UNLICENSED
pragma solidity 0.8.26;

import {ArtToken} from "contracts/ArtTokenUpgradeable.sol";
import { TestHelperOz5 } from "@layerzerolabs/test-devtools-evm-foundry/contracts/TestHelperOz5.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "forge-std/Test.sol";

abstract contract ContractUnderTestUpgradable is Test {
    uint256 public mainnetFork;
    ArtToken internal artTokenContract;

    address lzEndpoint =  0x1a44076050125825900e736c501f859c50fE728c; // base mainnet

    // Users
    address public proxyAdmin = makeAddr("proxyAdmin");
    address payable deployer = payable(makeAddr("deployer"));
    address payable user1 = payable(makeAddr("user1"));
    address payable user2 = payable(makeAddr("user2"));
    address payable unauthorizedUser = payable(makeAddr("unauthorizedUser"));
    address payable claimer1 = payable(makeAddr("claimer1"));
    address payable claimer2 = payable(makeAddr("claimer2"));

    // Constants
    uint256 public CLAIM_AMOUNT = 1000 * 10 ** 18;
    uint256 public INITIAL_MINT_AMOUNT = 1_000_000;

    function setUp() public virtual {

        // Mainnet fork
        string memory mainnet_rpc_url_key = "ALCHEMY_URL";
        string memory mainnet_rpc_url = vm.envString(mainnet_rpc_url_key);
        mainnetFork = vm.createFork(mainnet_rpc_url);

        vm.startPrank(deployer);

        artTokenContract = ArtToken(
            _deployContractAndProxy(
                type(ArtToken).creationCode,
                abi.encode(lzEndpoint),
                abi.encodeWithSelector(
                    ArtToken.initialize.selector,
                    "ArtTokenUpgradeable",
                    "ART_UPGRADEABLE",
                    deployer,
                    INITIAL_MINT_AMOUNT
                )
            )
        );

        vm.label({account: address(artTokenContract), newLabel: "ArtTokenUpgradeable"});

        artTokenContract.setClaimableSupply(CLAIM_AMOUNT * 3);

        vm.stopPrank();
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
}
