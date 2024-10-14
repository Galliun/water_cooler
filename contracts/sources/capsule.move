module galliun::capsule {
    // === Imports ===
    use std::string::String;
    use galliun::attributes::Attributes;

    // === Errors ===

    // === Structs ===
    /// Represents an NFT capsule with associated metadata.
    public struct Capsule has key, store {
        id: UID,
        collection_name: String,
        description: String,
        image_url: String,
        number: u64,
        attributes: Attributes,
        // This will be the water cooler ID and it will be used to
        // diferenciate one NFT collection from  another that was created using
        // water cooler protocol. (There will never be 2 water coolers with the same ID so this works)
        // batch_id: ID
    }

    // === Public View Functions ===

    /// Returns the number associated with the capsule.
    public fun number(self: &Capsule): u64 {
        self.number
    }

    // === Package Functions ===

    /// Creates a new `Capsule` object.
    public(package) fun new(
        number: u64,
        collection_name: String,
        description: String,
        image_url: String,
        attributes: Attributes,
        ctx: &mut TxContext,
    ): Capsule {
        Capsule {
            id: object::new(ctx),
            number,
            collection_name,
            description,
            image_url,
            attributes
        }
    }

    /// Returns a mutable reference to the UID of the capsule.
    public(package) fun uid_mut(self: &mut Capsule): &mut UID {
        &mut self.id
    }
}
