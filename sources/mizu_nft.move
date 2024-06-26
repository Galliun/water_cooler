module galliun::mizu_nft {
  // === Imports ===
    use std::string::{String};
    use galliun::attributes::{Attributes};

    // === Errors ===

    const EAttributesAlreadySet: u64 = 1;

    // === Structs ===

    // This is the structure that will be used to create the NFTs
    public struct MizuNFT has key, store {
        id: UID,
        // This name will be joined with the number to create the NFT name
        collection_name: String,
        description: String,
        // This url will be joined with the id to create the image url
        image_url: String,
        number: u64,
        attributes: Option<Attributes>,
        image: Option<String>,
        minted_by: Option<address>,
        // ID of the Kiosk assigned to the NFT.
        kiosk_id: ID,
        // ID of the KioskOwnerCap owned by the NFT.
        kiosk_owner_cap_id: ID,
    }

    // === Public view functions ===

    public fun number(self: &MizuNFT): u64 {
        self.number
    }

    public fun kiosk_id(self: &MizuNFT): ID {
        self.kiosk_id
    }

    public fun kiosk_owner_cap_id(self: &MizuNFT): ID {
        self.kiosk_owner_cap_id
    }

    // === Package Functions ===

    public(package) fun create_mizu_nft(
        number: u64,
        collection_name: String,
        description: String,
        image_url: String,
        attributes: Option<Attributes>,
        image: Option<String>,
        minted_by: Option<address>,
        kiosk_id: ID,
        kiosk_owner_cap_id: ID,
        ctx: &mut TxContext,
    ): MizuNFT {
        let nft = MizuNFT {
            id: object::new(ctx),
            number,
            collection_name,
            description,
            image_url,
            attributes,
            image,
            minted_by,
            kiosk_id,
            kiosk_owner_cap_id,
        };

        nft
    }

    public(package) fun get_id(self: &MizuNFT) : ID {
        object::id(self)
    }

    public(package) fun set_attributes(self: &mut MizuNFT, attributes: Attributes) {
        assert!(option::is_none(&self.attributes), EAttributesAlreadySet);
        option::fill(&mut self.attributes, attributes);
    }

    public(package) fun set_minted_by_address(self: &mut MizuNFT, addr: address) {
        option::fill(&mut self.minted_by, addr);
    }

    public(package) fun set_image(self: &mut MizuNFT, image: String) {
        option::fill(&mut self.image, image);
    }
}