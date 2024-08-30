module galliun::image {
    use std::string::{String};

    // === Imports ===

    // === Errors ===


    // === Structs ===


    public struct Image has key, store {
        id: UID,
        name: String,
        description: String,
        data: String, // Binary data of the image
    }


    // === Events ===

    

    // === Init Function ===

    /// Function to inscribe a new image on-chain
    #[allow(lint(self_transfer))]
    public fun inscribe_image(
        name: String, 
        description: String, 
        data: String, 
        ctx: &mut TxContext
    ) {
        let image = Image {
            id: object::new(ctx),
            name,
            description,
            data,
        };
        transfer::public_transfer(image, ctx.sender());
    }

    /// Function to get image metadata
    public fun get_image_metadata(image: &Image): (String, String, String) {
        (image.name, image.description, image.data)
    }
}
