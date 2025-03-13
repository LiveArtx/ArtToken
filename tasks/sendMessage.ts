import { BigNumberish, BytesLike } from 'ethers'
import { task } from 'hardhat/config'

import { getNetworkNameForEid, types } from '@layerzerolabs/devtools-evm-hardhat'
import { EndpointId } from '@layerzerolabs/lz-definitions'
import { Options, addressToBytes32 } from '@layerzerolabs/lz-v2-utilities'

interface Args {
    amount: string
    to: string
    toeid: EndpointId
}

interface SendParam {
    dstEid: EndpointId // Destination endpoint ID, represented as a number.
    to: BytesLike // Recipient address, represented as bytes.
    amountLD: BigNumberish // Amount to send in local decimals.
    minAmountLD: BigNumberish // Minimum amount to send in local decimals.
    extraOptions: BytesLike // Additional options supplied by the caller to be used in the LayerZero message.
    composeMsg: BytesLike // The composed message for the send() operation.
    oftCmd: BytesLike // The OFT command to be executed, unused in default OFT implementations.
}

// send tokens from a contract on one network to another
task('lz:oft:send', 'Sends tokens from either OFT or OFTAdapter')
    .addParam('to', 'contract address on network B', undefined, types.string)
    .addParam('toeid', 'destination endpoint ID', undefined, types.eid)
    .addParam('amount', 'amount to transfer in token decimals', undefined, types.string)
    .setAction(async (taskArgs: Args, { ethers, deployments }) => {
        const toAddress = taskArgs.to
        const eidB = taskArgs.toeid

        // Get the contract deployment details
        const oftDeployment = await deployments.get('MyOFT')

        const [signer] = await ethers.getSigners()

        // Create contract instance
        const oftContract = new ethers.Contract(oftDeployment.address, oftDeployment.abi, signer)

        console.log(`Amount argument received: ${taskArgs.amount}`)
        if (!taskArgs.amount) {
            throw new Error("Amount argument is missing or undefined.")
        }

        const decimals = await oftContract.decimals()
        console.log(`Token decimals: ${decimals}`)
        if (!decimals && decimals !== 0) {
            throw new Error("Could not retrieve token decimals.")
        }

        const amount = ethers.utils.parseUnits(taskArgs.amount, decimals)
        const options = Options.newOptions().addExecutorLzReceiveOption(65000, 0).toBytes()
     


        // Convert recipient address to bytes32 format
        const toBytes = addressToBytes32(toAddress)
        console.log(`Original address: ${toAddress}`)
        console.log(`Recipient address in bytes32 format: ${toBytes}`)

        if (!toBytes || toBytes.length !== 32) {
            throw new Error("Invalid recipient address conversion.")
        }

        const sendParam: SendParam = {
            dstEid: eidB,
            to: toBytes,
            amountLD: amount,
            minAmountLD: amount,
            extraOptions: options,
            composeMsg: ethers.utils.arrayify('0x'), // Assuming no composed message
            oftCmd: ethers.utils.arrayify('0x'), // Assuming no OFT command is needed
        }

        // Get the quote for the send operation
        const feeQuote = await oftContract.quoteSend(sendParam, false)
        const nativeFee = feeQuote.nativeFee

        console.log(`Sending ${taskArgs.amount} token(s) to network ${getNetworkNameForEid(eidB)} (${eidB})`)

        // Retrieve the inner token address
        const innerTokenAddress = await oftContract.token()
        console.log(`Inner token address: ${innerTokenAddress}`)

        if (innerTokenAddress !== oftContract.address) {
            console.log(`Detected OFT Adapter. Approving ${amount.toString()} tokens for transfer.`)

            // Use `getContractAt` instead of `getContractFactory` to interact with the already deployed ERC20 token
            const innerToken = await ethers.getContractAt("ERC20", innerTokenAddress)

            // Approve the amount to be spent by the oft contract
            const approveTx = await innerToken.approve(oftDeployment.address, amount)
            await approveTx.wait()
            console.log("Approval successful.")
        }

        // Initiate the send transaction
        const r = await oftContract.send(sendParam, { nativeFee: nativeFee, lzTokenFee: 0 }, signer.address, {
            value: nativeFee,
        })

        console.log(`Send tx initiated. See: https://layerzeroscan.com/tx/${r.hash}`)
    })
