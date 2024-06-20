module galliun::collection {

    // === Constants ===

    const COLLECTION_SIZE: u16 = 3333;

    // === Structs ===

    public struct COLLECTION has drop {}

    // === Init Function ===

    #[allow(unused_function)]
    fun init(
        _otw: COLLECTION,
        _ctx: &mut TxContext,
    ) {}

    // == Public-Friend Functions ===

    public(package) fun size(): u16 {
        COLLECTION_SIZE
    }
}