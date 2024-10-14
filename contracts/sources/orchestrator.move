module galliun::orchestrator {
    // === Imports ===

    use std::string::{Self, String};
    use sui::{
        coin::{Self, Coin},
        display::{Self},
        package::{Self},
        sui::{SUI},
        transfer_policy::{TransferPolicy},
        event,
        kiosk::{Kiosk, KioskOwnerCap},
    };
    use galliun::{
        water_cooler::{Self, WaterCooler, WaterCoolerAdminCap},
        capsule::{Self, Capsule},
        attributes::{Self}
    };

    // === Errors ===
    
    const EInvalidPaymentAmount: u64 = 1;
    const EInvalidTicketForMintPhase: u64 = 2;
    const EMintNotLive: u64 = 3;
    const ETicketWaterCoolerMissMatch: u64 = 4;
    const EWrongPhase: u64 = 5;


    // === Constants ===

    // const MINT_STATE_INACTIVE: u8 = 0;
    const MINT_STATE_ACTIVE: u8 = 1;

    // === Structs ===

    public struct ORCHESTRATOR has drop {}

    public struct WhitelistTicket has key {
        id: UID,
        waterCoolerId: ID,
        name: String,
        image_url: String,
        /// This is the number of NFTs they are allowed to mint
        allowed_mints: u8,
        /// This is how we keep track of the number
        phase: u8,
    }

    public struct OriginalGangsterTicket has key {
        id: UID,
        waterCoolerId: ID,
        name: String,
        image_url: String,
        /// This is the number of NFTs they are allowed to mint
        allowed_mints: u8,
        /// This is how we keep track of the number
        phase: u8,
    }

    // ====== Events ======

    public struct NFTMinted has copy, drop {
        nft_id: ID,
        kiosk_id: ID,
        minter: address,
    }


    // === Init Function ===

    fun init(
        otw: ORCHESTRATOR,
        ctx: &mut TxContext,
    ) {
        let publisher = package::claim(otw, ctx);


        let mut wl_ticket_display = display::new<WhitelistTicket>(&publisher, ctx);
        display::add(&mut wl_ticket_display, string::utf8(b"name"), string::utf8(b"{name} WL Ticket"));
        display::add(&mut wl_ticket_display, string::utf8(b"description"), string::utf8(b"{description}"));
        display::add(&mut wl_ticket_display, string::utf8(b"image_url"), string::utf8(b"{image_url}"));
        display::update_version(&mut wl_ticket_display);

        transfer::public_transfer(wl_ticket_display, ctx.sender());

        let mut og_ticket_display = display::new<OriginalGangsterTicket>(&publisher, ctx);
        display::add(&mut og_ticket_display, string::utf8(b"name"), string::utf8(b"{name} OG Ticket"));
        display::add(&mut og_ticket_display, string::utf8(b"description"), string::utf8(b"{description}"));
        display::add(&mut og_ticket_display, string::utf8(b"image_url"), string::utf8(b"{image_url}"));
        display::update_version(&mut og_ticket_display);


        transfer::public_transfer(og_ticket_display, ctx.sender());
        transfer::public_transfer(publisher, ctx.sender());
    }

     // === Public-view Functions ===


    // === Public-Mutative Functions ===


    public entry fun public_mint(
        waterCooler: &mut WaterCooler,
        policy: &TransferPolicy<Capsule>,
        kiosk: Kiosk,
        kiosk_owner_cap: KioskOwnerCap,
        payment: Coin<SUI>,        
        ctx: &mut TxContext,
    ) {
        assert!(waterCooler.phase() == 3, EWrongPhase);
        assert!(waterCooler.status() == MINT_STATE_ACTIVE, EMintNotLive);
        assert!(waterCooler.price() == payment.value(), EInvalidPaymentAmount);

        mint_capsule(
            waterCooler,
            policy,
            kiosk,
            kiosk_owner_cap,
            payment,
            ctx
        );
    }

    #[allow(unused_variable)]
    public fun whitelist_mint(
        ticket: WhitelistTicket,
        waterCooler: &mut WaterCooler,
        policy: &TransferPolicy<Capsule>,
        kiosk: Kiosk,
        kiosk_owner_cap: KioskOwnerCap,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        assert!(object::id(waterCooler) == ticket.waterCoolerId, ETicketWaterCoolerMissMatch);

        let WhitelistTicket { id, name, image_url, waterCoolerId, allowed_mints, phase } = ticket;
        
        assert!(waterCooler.status() == MINT_STATE_ACTIVE, EMintNotLive);
        assert!(phase == waterCooler.phase(), EInvalidTicketForMintPhase);
        assert!(waterCoolerId == object::id(waterCooler), EInvalidTicketForMintPhase);
        assert!(payment.value() == waterCooler.price(), EInvalidPaymentAmount);

        mint_capsule(
            waterCooler,
            policy,
            kiosk,
            kiosk_owner_cap,
            payment,
            ctx
        );

        if(allowed_mints > 0) {
            let new_allowed_mints = allowed_mints - 1;
            let og_ticket = create_wl_ticket(waterCooler, new_allowed_mints, ctx);
            transfer::transfer(og_ticket, ctx.sender());
            id.delete();
        } else {
            id.delete();
        }
    }

    #[allow(unused_variable)]
    public fun og_mint(
        ticket: OriginalGangsterTicket,
        waterCooler: &mut WaterCooler,
        policy: &TransferPolicy<Capsule>,
        kiosk: Kiosk,
        kiosk_owner_cap: KioskOwnerCap,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        assert!(object::id(waterCooler) == ticket.waterCoolerId, ETicketWaterCoolerMissMatch);

        let OriginalGangsterTicket { id, name, image_url, waterCoolerId, allowed_mints, phase } = ticket;
        
        assert!(waterCooler.status() == MINT_STATE_ACTIVE, EMintNotLive);
        assert!(phase == waterCooler.phase(), EInvalidTicketForMintPhase);
        assert!(payment.value() == waterCooler.price(), EInvalidPaymentAmount);

        mint_capsule(
            waterCooler,
            policy,
            kiosk,
            kiosk_owner_cap,
            payment,
            ctx
        );

        if(allowed_mints > 0) {
            let new_allowed_mints = allowed_mints - 1;
            let og_ticket = create_og_ticket(waterCooler, new_allowed_mints, ctx);
            transfer::transfer(og_ticket, ctx.sender());
            id.delete();
        } else {
            id.delete();
        }
    }

    // === Admin functions ===

    public fun ditribute_og_ticket(
        waterCooler: &WaterCooler,
        cap: &WaterCoolerAdminCap,
        mut addresses: vector<address>,
        allowed_mints: u8,
        ctx: &mut TxContext
    ) {
        waterCooler.checkWaterCoolerCap(cap);

        while(addresses.length() > 0) {
            let og_ticket = create_og_ticket(waterCooler, allowed_mints, ctx);
            transfer::transfer(og_ticket, addresses.pop_back());
        }
    }
    
    fun create_og_ticket(
        waterCooler: &WaterCooler,
        allowed_mints: u8,
        ctx: &mut TxContext
    ): OriginalGangsterTicket {
        OriginalGangsterTicket {
            id: object::new(ctx),
            name: water_cooler::name(waterCooler),
            waterCoolerId: object::id(waterCooler),
            image_url: water_cooler::placeholder_image(waterCooler),
            allowed_mints,
            phase: 1
        }
    }

    public fun ditribute_wl_ticket(
        waterCooler: &WaterCooler,
        cap: &WaterCoolerAdminCap,
        mut addresses: vector<address>,
        allowed_mints: u8,
        ctx: &mut TxContext
    ) {
        waterCooler.checkWaterCoolerCap(cap);

        while(addresses.length() > 0) {
            let whitelist_ticket = create_wl_ticket(waterCooler, allowed_mints, ctx);

            transfer::transfer(whitelist_ticket, addresses.pop_back());
        }
    }

    public fun create_wl_ticket(
        waterCooler: &WaterCooler,
        allowed_mints: u8,
        ctx: &mut TxContext
    ): WhitelistTicket {
        WhitelistTicket {
            id: object::new(ctx),
            name: water_cooler::name(waterCooler),
            waterCoolerId: object::id(waterCooler),
            image_url: water_cooler::placeholder_image(waterCooler),
            allowed_mints,
            phase: 2
        }
    }

    // === Package functions ===

    

    // === Private Functions ===

#[allow(lint(self_transfer, share_owned))]
fun mint_capsule(
    waterCooler: &mut WaterCooler,
    policy: &TransferPolicy<Capsule>,
    mut kiosk: Kiosk,
    kiosk_owner_cap: KioskOwnerCap,
    mut payment: Coin<SUI>,
    ctx: &mut TxContext,
) {

    // Retrieve metadata and resolve any borrowing of `ctx` immediately
    let (number, image_url, keys, values) = waterCooler.get_metadata(ctx);

    // Clone or copy values to avoid borrowing conflicts
    let image_url_copy = *image_url;
    let key_copy = *keys;
    let value_copy = *values;

    // Now, use the copied values to create attributes and call other functions
    let attributes = attributes::new(key_copy, value_copy, ctx);

    // Use the attributes reference as needed
    let attributes_ref = attributes;

    // Create the NFT using the values and `ctx` after resolving all previous borrows
    let nft: Capsule = capsule::new(
        number,
        waterCooler.name(),
        waterCooler.description(),
        image_url_copy,
        attributes_ref,
        // object::id(waterCooler),
        ctx,
    );

    // Emit an event for the minted NFT
    event::emit(NFTMinted { 
        nft_id: object::id(&nft),
        kiosk_id: object::id(&kiosk),
        minter: ctx.sender(),
    });

    // Lock the NFT in the kiosk
    kiosk.lock(&kiosk_owner_cap, policy, nft);

    // Transfer the kiosk owner capability to the sender (owner)
    transfer::public_transfer(kiosk_owner_cap, ctx.sender());

    // Share the kiosk object publicly
    transfer::public_share_object(kiosk);

    // Deduct minting fee from the payment
    let coin_balance = payment.balance_mut();
    let profits = coin::take(coin_balance, waterCooler.mint_fee(), ctx);

    // Send the profits to factory settings
    water_cooler::send_fees(profits);

    // Send the remaining payment to the water cooler
    waterCooler.send_payment(payment);
}


    // === Test Functions ===
    #[test_only]
    public fun init_for_mint(ctx: &mut TxContext) {
        init(ORCHESTRATOR {}, ctx);
    }
}
