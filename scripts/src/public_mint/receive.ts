import { Transaction } from '@mysten/sui/transactions';
import { client, user1_keypair, find_one_by_type } from '../helpers.js';
import data from '../../deployed_objects.json';
import user_data from './user_objects.json';
import fs from 'fs';
import path from "path";

const keypair = user1_keypair();

const packageId = data.packageId;

const mizu = user_data.user_objects.mizu_nft;
const kiosk_cap_id = user_data.user_objects.mizu_kiosk_cap;

(async () => {
    const txb = new Transaction;

    console.log("User1 taking kioskownercap");

    const [kiosk_cap, potato] = txb.moveCall({
        target: `${packageId}::receive::receive_kiosk_owner_cap`,
        arguments: [
            txb.object(mizu),
            txb.object(kiosk_cap_id)
        ],
    });

    txb.moveCall({
        target: `${packageId}::receive::return_kiosk_owner_cap`,
        arguments: [
            txb.object(kiosk_cap),
            txb.object(potato)
        ],
    });

    const { objectChanges } = await client.signAndExecuteTransaction({
        signer: keypair,
        transaction: txb,
        options: { showObjectChanges: true }
    });

    if (!objectChanges) {
        console.log("Error: objectChanges is null or undefined");
        process.exit(1);
    }

    console.log(objectChanges);

    console.log('Updated user_objects.json successfully');
})()
