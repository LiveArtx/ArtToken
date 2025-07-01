import { ethers } from 'ethers';
import * as fs from 'fs';
import * as path from 'path';
import 'dotenv/config';

// Usage: ts-node scripts/changeOwnership.ts <newOwnerAddress> <rpcUrl>

const CONTRACT_ADDRESS = '0x4DEC3139f4A6c638E26452d32181fe87A7530805';
const ABI_PATH = path.join(__dirname, '../deployments/base/ArtTokenUpgradeable.json');

async function main() {
  const newOwner = process.argv[2];
  const rpcUrl = process.argv[3];
  if (!newOwner || !ethers.utils.isAddress(newOwner) || !rpcUrl) {
    console.error('Usage: ts-node scripts/changeOwnership.ts <newOwnerAddress> <rpcUrl>');
    process.exit(1);
  }

  const PRIVATE_KEY = process.env.PRIVATE_KEY;
  if (!PRIVATE_KEY) {
    console.error('Missing PRIVATE_KEY in environment variables.');
    process.exit(1);
  }

  // Load ABI
  const abiJson = JSON.parse(fs.readFileSync(ABI_PATH, 'utf8'));
  const abi = abiJson.abi;

  // Connect to provider and wallet
  const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
  const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

  // Connect to contract
  const contract = new ethers.Contract(CONTRACT_ADDRESS, abi, wallet);

  try {
    const tx = await contract.transferOwnership(newOwner);
    console.log('Transaction sent! Hash:', tx.hash);
    const receipt = await tx.wait();
    console.log('Transaction confirmed in block', receipt.blockNumber);
    console.log('Receipt:', receipt);
  } catch (err) {
    console.error('Error sending transaction:', err);
    process.exit(1);
  }
}

main();
