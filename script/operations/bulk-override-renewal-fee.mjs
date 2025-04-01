import { ethers } from "ethers";
import fs from "fs";
import dotenv from "dotenv";

dotenv.config();

const provider = new ethers.JsonRpcProvider(process.env.RONIN_MAINNET_RPC);
const wallet = new ethers.Wallet(process.env.RONIN_MAINNET_PK, provider);
const renewList = JSON.parse(fs.readFileSync("renew-list.json", "utf8"));
// Verify: https://app.roninchain.com/address/0xcd245263eddee593a5a66f93f74c58c544957339
const rnsOperation = "0xcd245263eddee593a5a66f93f74c58c544957339";
const abi = ["function bulkOverrideRenewalFees(string[] calldata labels, uint256[] calldata yearlyUSDPrices) external"];
// 0 if we want to bulk renew all labels
// 5 if we want to reset renewal fee back to 5 usd
const defaultFee = 0;
const fees = renewList.map((_) => defaultFee);
const account = "0x4BFEc2a63B72c67e6c3f599fCc40E1d42AE519ff";

console.log({ fees });

const contract = new ethers.Contract(rnsOperation, abi, provider);
const shouldSimulate = true;

if (shouldSimulate) {
	try {
		await contract.bulkOverrideRenewalFees.staticCall(renewList, fees, {
			from: account,
		});
	} catch (error) {
		console.error("Failed to simulate bulk override renewal fees", error);
	}
	console.log("Simulate Bulk override renewal fees success");
} else {
	try {
		const tx = await contract.connect(wallet).bulkOverrideRenewalFees(renewList, fees);
		await tx.wait();
	} catch (error) {
		console.error("Failed to bulk override renewal fees", error);
	}

	console.log("Bulk override renewal fees success");
}
