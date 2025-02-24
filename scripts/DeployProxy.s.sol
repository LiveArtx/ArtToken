// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "src/upgradable/ArtToken";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// forge script script/DeployProxy.s.sol:DeployProxyScript --rpc-url $RPC_URL --broadcast  -vvvv --via-ir

// https://docs.openzeppelin.com/upgrades-plugins/1.x/api-foundry-upgrades#Upgrades-Upgrades-deployTransparentProxy-string-address-bytes-

//https://docs.openzeppelin.com/upgrades-plugins/1.x/api-core#define-reference-contracts

contract DeployProxyScript is Script {
    bool public dryRun = false;
    
    address initialOwner;
    string  tokenName;
    string  tokenSymbol; 
    uint256 initialMintAmount;

    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("PK");
        address derivedAddress = vm.addr(privateKey);
        address initialOwner = derivedAddress;
        
        if (dryRun) {
            uint256 startGas = gasleft();
            uint256 gasPrice = block.basefee; // Get current network gas price
            
            // Create initialization data
            bytes memory initData = abi.encodeCall(
                ArtToken.initialize,
                (initialOwner, tokenName, tokenSymbol,initialMintAmount)
            );

            // Simulate deployment without broadcasting
            vm.startPrank(derivedAddress);
            
            // Deploy implementation (dry run)
            ArtToken implementation = new ArtToken();
            
            // Deploy proxy (dry run)
            TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
                address(implementation),
                initialOwner,
                initData
            );

            vm.stopPrank();
            
            uint256 gasUsed = startGas - gasleft();
            uint256 gasCostInWei = gasUsed * gasPrice;
            console.log("Current gas price (gwei):", gasPrice / 1e9);
            console.log("Estimated gas used:", gasUsed);
            console.log("Estimated cost in ETH: %s", vm.toString(gasCostInWei / 1e18));
            console.log("Estimated cost in gwei: %s", vm.toString(gasCostInWei / 1e9));
        } else {
            uint256 startGas = gasleft();
            
            // Original deployment code
            vm.startBroadcast(privateKey);
            
            address proxy = Upgrades.deployTransparentProxy(
                "upgradable/ArtToken.sol",
                initialOwner,
                abi.encodeCall(
                    ArtToken.initialize,
                    (initialOwner, tokenName, tokenSymbol,initialMintAmount)
                )
            );

            uint256 gasUsed = startGas - gasleft();
            uint256 gasCostInEth = gasUsed * tx.gasprice;
            console.log("Proxy deployed at:", address(proxy));
            console.log("Total gas used:", gasUsed);
            console.log("Total cost in ETH:", gasCostInEth / 1e18);
            
            vm.stopBroadcast();
        }
    }
}







