import { ethers } from "ethers";
import fs from "fs";
import dotenv from "dotenv";

dotenv.config();

const provider = new ethers.JsonRpcProvider("https://api-archived.roninchain.com/rpc");
const wallet = new ethers.Wallet(process.env.RONIN_MAINNET_PK, provider);
const renewList = JSON.parse(fs.readFileSync("renew-list.json", "utf8"));
// Verify: https://app.roninchain.com/address/0x662852853614cbbb5d04bf2e29955b97e3c50b69
const ronRegistrarControllerAddr = "0x662852853614cbbb5d04bf2e29955b97e3c50b69";
const abi = ["function renew(string calldata name, uint64 duration) external payable"];
const defaultRenewDuration = 5 * 365 * 24 * 60 * 60; // 5 years
// Structure of data.json is assumed to be like this:
// ["label1", "label2", "label3", ...]
const durations = renewList.map(() => defaultRenewDuration);
// Get current nonce of account
let nonce = await wallet.getNonce();
console.log(`Current nonce: ${nonce}`);
const account = wallet.address;
const shouldSimulate = true;
// Assert the list is unique
if (new Set(renewList).size !== renewList.length) {
	console.error("List is not unique");
	process.exit(1);
}

async function bulkRenew() {
	const contract = new ethers.Contract(ronRegistrarControllerAddr, abi, provider);

	const promises = renewList.map(async (label) => {
		if (shouldSimulate) {
			console.log(`nonce: ${nonce++}`);
			try {
				await contract.renew.staticCall(label, defaultRenewDuration, {
					from: account,
				});
			} catch (error) {
				console.error(`Failed to simulate renew for ${label} - ${defaultRenewDuration}`, error);
			}
		} else {
			console.log(`nonce: ${nonce}`);
			try {
				await contract.connect(wallet).renew(label, defaultRenewDuration, {
					nonce: nonce++,
				});
				console.log(`Renew for label ${label} - duration: ${defaultRenewDuration} success`);
			} catch (error) {
				console.error(`Failed to renew label ${label} - duration ${defaultRenewDuration}:`, error);
			}
		}
	});

	await Promise.all(promises);
}

bulkRenew();
