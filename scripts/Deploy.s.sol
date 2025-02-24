// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/ArtToken.sol"

// forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --broadcast  -vvvv --via-ir

contract DeployScript is Script {
    address initialOwner;
    string  tokenName;
    string  tokenSymbol; 
    uint256 initialMintAmount;

    function setUp() public {}

    function run() public {
        // Get private key from environment variable
        uint256 privateKey = vm.envUint("PK");
        
        // Start broadcasting transactions
        vm.startBroadcast(privateKey);

        // Deploy the mock token
        ArtToken artToken = new ArtToken(initialOwner, tokenName, tokenSymbol,initialMintAmount);

        vm.stopBroadcast();

        // Log the deployment address
        console.log("ArtToken deployed to:", address(artToken));
    }
}