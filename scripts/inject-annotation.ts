/**
 * This script injects annotations into @layerzerolabs/oft-evm-upgradeable/contracts and @layerzerolabs/oapp-evm-upgradeable/contracts files.
 * It is used to prevent the compiler from throwing warnings about the @custom:oz-upgrades-unsafe-allow constructor state-variable-immutable annotation when compiling/upgrading the contracts.
 * 
 * Example Cmd: node scripts/inject-annotation.ts
 */

const fs = require("fs");
const path = require("path");

// BASE PATHS
const oftBasePath = "../node_modules/@layerzerolabs/oft-evm-upgradeable/contracts";
const oappBasePath = "../node_modules/@layerzerolabs/oapp-evm-upgradeable/contracts";

// PATHS
const oftPaths = [
    `${oftBasePath}/oft/OFTUpgradeable.sol`,
    `${oftBasePath}/oft/OFTCoreUpgradeable.sol`,
    `${oappBasePath}/oapp/OAppCoreUpgradeable.sol`,
    `${oappBasePath}/oapp/OAppUpgradeable.sol`,
    `${oappBasePath}/oapp/OAppCoreUpgradeable.sol`
];

// IGNORE ANNOTATIONS
const ignoreImmutable = "/// @custom:oz-upgrades-unsafe-allow state-variable-immutable";
const ignoreConstructorAndImmutable = "/// @custom:oz-upgrades-unsafe-allow constructor state-variable-immutable";

const keywordCommentPairs = [
    { keyword: "constructor(", comment: ignoreConstructorAndImmutable, insertBelow: false },
    { keyword: "uint256 public immutable decimalConversionRate;", comment: ignoreImmutable, insertBelow: false },
    { keyword: "ILayerZeroEndpointV2 public immutable endpoint;", comment: ignoreImmutable, insertBelow: false }
];

oftPaths.forEach((relativePath) => {
    const filePath = path.join(__dirname, relativePath);
    let fileContent = fs.readFileSync(filePath, "utf8");

    keywordCommentPairs.forEach(({ keyword, comment, insertBelow }) => {
        if (!fileContent.includes(comment)) {
            const keywordIndex = fileContent.indexOf(keyword);
            if (keywordIndex !== -1) {
                if (insertBelow) {
                    // Insert comment below the line
                    const endOfLineIndex = fileContent.indexOf("\n", keywordIndex);
                    fileContent = fileContent.slice(0, endOfLineIndex + 1) + comment + "\n" + fileContent.slice(endOfLineIndex + 1);
                } else {
                    // Insert comment above the line
                    fileContent = fileContent.slice(0, keywordIndex) + comment + "\n" + fileContent.slice(keywordIndex);
                }
            }
        }
    });

    fs.writeFileSync(filePath, fileContent, "utf8");
    console.log(`Updated file: ${filePath}`);
});
