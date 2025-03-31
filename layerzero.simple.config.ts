import { EndpointId } from '@layerzerolabs/lz-definitions'
import { ExecutorOptionType } from '@layerzerolabs/lz-v2-utilities'
import { generateConnectionsConfig } from '@layerzerolabs/metadata-tools'
import { OAppEnforcedOption, OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

// https://docs.layerzero.network/v2/developers/evm/create-lz-oapp/configuring-pathways

// https://docs.layerzero.network/v2/developers/evm/technical-reference/simple-config

// @dev execution types to handle different enforcedOptions
// uint16 internal constant SEND = 1; // a standard token transfer via send()
// uint16 internal constant SEND_AND_CALL = 2; // a composed token transfer via send()

const lineaContract: OmniPointHardhat = {
    eid: EndpointId.LINEASEP_V2_TESTNET,
    contractName: 'ArtTokenUpgradeable',
}

const baseContract: OmniPointHardhat = {
    eid: EndpointId.BASESEP_V2_TESTNET,
    contractName: 'ArtTokenUpgradeable',
}

const EVM_ENFORCED_OPTIONS: OAppEnforcedOption[] = [
    {
        msgType: 1,
        optionType: ExecutorOptionType.LZ_RECEIVE,
        gas: 80000,
        value: 0,
    },
    {
        msgType: 2,
        optionType: ExecutorOptionType.LZ_RECEIVE,
        gas: 80000,
        value: 0,
    },
    {
        msgType: 2,
        optionType: ExecutorOptionType.COMPOSE,
        index: 0,
        gas: 80000,
        value: 0,
    },
]

export default async function () {
    const connections = await generateConnectionsConfig([
        [
            lineaContract, // srcContract
            baseContract, // dstContract
            [['LayerZero Labs'], []], // [ requiredDVN[], [ optionalDVN[], threshold ] ]
            [1, 1], // [srcToDstConfirmations, dstToSrcConfirmations]
            [EVM_ENFORCED_OPTIONS, EVM_ENFORCED_OPTIONS], // [enforcedOptionsSrcToDst, enforcedOptionsDstToSrc]
        ],

        [
            baseContract, // srcContract
            lineaContract, // dstContract
            [['LayerZero Labs'], []], // [ requiredDVN[], [ optionalDVN[], threshold ] ]
            [1, 1], // [srcToDstConfirmations, dstToSrcConfirmations]
            [EVM_ENFORCED_OPTIONS, EVM_ENFORCED_OPTIONS], // [enforcedOptionsSrcToDst, enforcedOptionsDstToSrc]
        ],
    ])

    return {
        contracts: [{ contract: lineaContract }, { contract: baseContract }],
        connections,
    }
}