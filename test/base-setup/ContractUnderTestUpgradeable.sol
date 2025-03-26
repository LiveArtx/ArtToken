// SPDX-License-Identifier: MIT UNLICENSED
pragma solidity 0.8.26;

import {ArtToken} from "contracts/ArtTokenUpgradeable.sol";
import {OFTTest} from "@layerzerolabs/oft-evm-upgradeable/test/OFT.t.sol";

abstract contract ContractUnderTestUpgradable is OFTTest {
    uint256 public mainnetFork;
    ArtToken internal artTokenContract;
    address lzEndpoint =  0x1a44076050125825900e736c501f859c50fE728c; // base mainnet

    // Users
    address payable deployer = payable(makeAddr("deployer"));
    address payable user1 = payable(makeAddr("user1"));
    address payable user2 = payable(makeAddr("user2"));
    address payable unauthorizedUser = payable(makeAddr("unauthorizedUser"));
    address payable claimer1 = payable(makeAddr("claimer1"));
    address payable claimer2 = payable(makeAddr("claimer2"));

    // Constants
    uint256 public CLAIM_AMOUNT = 1000 * 10 ** 18;
    uint256 public INITIAL_MINT_AMOUNT = 1_000_000;

    function setUp() public virtual override {

        // Mainnet fork
        string memory mainnet_rpc_url_key = "MAINNET_RPC_URL";
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
}
