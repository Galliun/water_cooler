/*
 * Copyright (c) 2024 Studio Mirai, Ltd.
 * SPDX-License-Identifier: MIT
 */

/*
 * This code has been modified and is maintained by Galliun
 * Copyright (c) 2024 Galliun, Limited.
 * SPDX-License-Identifier: MIT
 */

module galliun::attributes {
    // === Imports ===
    use std::string::String;
    use sui::vec_map::{Self, VecMap};

    // === Error ===
    const EKeyValueCountMissMatch: u64 = 0;

    // === Structs ===
    /// Represents the attributes of an `NFT` object.
    public struct Attributes has key, store {
        id: UID,
        fields: VecMap<String, String>,
    }

    // === Package Functions ===
    /// Creates a new `Attributes` object with the given keys and values.
    public(package) fun new(
        keys: vector<String>,
        values: vector<String>,
        ctx: &mut TxContext,
    ): Attributes {
        // Ensure keys and values vectors have the same length
        assert!(keys.length() == values.length(), EKeyValueCountMissMatch);

        Attributes {
            id: object::new(ctx),
            fields: vec_map::from_keys_values(keys, values),
        }
    }
}