module galliun::water_cooler {
    // === Imports ===
    use std::string::{Self, String};
    use sui::{
        balance::{Self, Balance},
        sui::SUI,
        coin::{Self, Coin},
        display,
        table_vec::{Self, TableVec},
        table::{Self, Table},
        transfer_policy,
    };
    use galliun::{
        capsule::{Capsule},
        pseudo_random,
    };

    // === Errors ===

    const EWaterCoolerAlreadyInitialized: u64 = 0;
    const EWaterCoolerCapMissMatch: u64 = 1;
    const EInvalidnftNumber: u64 = 2;
    const EWaterCoolerAlreadyInitilized: u64 = 3;
    const EInvalidStatusNumber: u64 = 4;
    const EInvalidPrice: u64 = 5;
    const EInvalidPhaseNumber: u64 = 6;

    // === Constants ===

    const MINT_STATE_INACTIVE: u8 = 0;
    const MINT_STATE_ACTIVE: u8 = 1;

    // === Structs ===


    public struct WATER_COOLER has drop {}

    // This is the structure of WaterCooler that will be loaded with and distribute the NFTs
    public struct WaterCooler has key {
        id: UID,

        // === Start Collection details ===

        // The name of the NFT collection
        name: String,
        // The description of the NFT collection
        description: String,
        // We concatinate this url with the number of the NFT in order to find it on chain
        image_url: String,
        // This is the image that will be displayed on your NFT until they are revealed
        ticket_image_url: String,
        // This is the address to where the royalty and mint fee will be sent
        treasury: address,
        supply: u64,
        // Stores the address of the wallet that created the Water Cooler
        owner: address,
        // This to let us know if all the NFT metadata has been added to the registry
        is_initialized: bool,

        /// This counter is to keep track of the number of NFT metadata that has been added to the registry
        init_counter: u64,
        // balance for creator
        balance: Balance<SUI>,

        // === End Collection details ===

        // === Start Registry details ===

        // This is to keep track of the NFTs that remain to be
        // distributed
        remaining: TableVec<u64>,
        // this keeps track of weather an NFT has already been distributed or not
        nft_nums_retrieved: Table<u64, bool>,
        // a table to keep track of the image that is associated with the NFT number
        num_to_image: Table<u64, String>,
        // a table to keep track of the keys and the values for attributes that is associated with the NFT number
        num_to_keys: Table<u64, vector<String>>,
        num_to_values: Table<u64, vector<String>>,
        // Counter to keep track of the number of NFTs that have been retrived
        retrieve_couter: u64,

        // === End Registry details ===


        // === Start Mint Settings details ===

        // This is the price that must be paid by the minter to get the NFT
        price: u64,
        /// The phase determins the current minting phase
        /// 1 = og
        /// 2 = whiteList
        /// 3 = public
        phase: u8,
        /// The state determings whether the mint is active or not
        /// 0 = inactive
        /// 1 = active
        status: u8,

        // === End Mint Settings details ===

        
        // This bool determins wether or not a to display the Water cooler on the launchpad
        display: bool,
        // Fee to be paid by the person minting the NFT
        mint_fee: u64
    }

    // Admin cap of this Water Cooler to be used but the Cooler owner when making changes
    public struct WaterCoolerAdminCap has key { id: UID, `for`: ID }

    // === Public mutative functions ===

    #[allow(lint(share_owned))]
    fun init(otw: WATER_COOLER, ctx: &mut TxContext) {
        // Claim the Publisher object.
        let publisher = sui::package::claim(otw, ctx);

        let mut display = display::new<Capsule>(&publisher, ctx);
        display::add(&mut display, string::utf8(b"name"), string::utf8(b"{collection_name} #{number}"));
        display::add(&mut display, string::utf8(b"description"), string::utf8(b"{description}"));
        display::add(&mut display, string::utf8(b"image_url"), string::utf8(b"{image_url}"));
        display::add(&mut display, string::utf8(b"attributes"), string::utf8(b"{attributes}"));
        display::update_version(&mut display);

        let (policy, policy_cap) = transfer_policy::new<Capsule>(&publisher, ctx);
        
        transfer::public_transfer(publisher, ctx.sender());
        transfer::public_transfer(policy_cap,ctx.sender());
        transfer::public_transfer(display, ctx.sender());

        transfer::public_share_object(policy);
    }

    // === Package Functions ===

    // The function that allow the Cooler Factory to create coolers and give them to creators
    public(package) fun new(
        name: String,
        description: String,
        image_url: String,
        ticket_image_url: String,
        supply: u64,
        treasury: address,
        ctx: &mut TxContext
    ): ID {
        let waterCooler = WaterCooler {
            id: object::new(ctx),
            name,
            description,
            image_url,
            ticket_image_url,
            treasury,
            supply,
            owner: ctx.sender(),
            is_initialized: false,
            init_counter: 0,
            balance: balance::zero(),
            remaining: table_vec::empty(ctx),
            nft_nums_retrieved: table::new(ctx),
            num_to_image: table::new(ctx),
            num_to_keys: table::new(ctx),
            num_to_values: table::new(ctx),
            retrieve_couter: 0,
            price: 0,
            phase: 0,
            status: 0,
            display: false,
            mint_fee: 10_000_000
        };

        transfer::transfer(
            WaterCoolerAdminCap { 
                id: object::new(ctx),
                `for`: object::id(&waterCooler)
            },
            ctx.sender()
        );

        let waterCoolerId = object::id(&waterCooler);

        transfer::share_object(waterCooler);
        
        waterCoolerId
    }

    // This is how the fees are sent to the NFT collection creator
    public(package) fun send_payment(
        self: &WaterCooler,
        coins: Coin<SUI>
    ) {
        transfer::public_transfer(coins, self.treasury);
    }

    // Pay the fees to galliun labs
    public(package) fun send_fees(
        coins: Coin<SUI>
    ) {
        transfer::public_transfer(coins, @galliun_treasury);
    }
    
    public(package) fun get_is_initialized(
        self: &WaterCooler,
    ): bool {
        self.is_initialized
    }

    public(package) fun add_balance(
        self: &mut WaterCooler,
        coin: Coin<SUI>
    ) {
        self.balance.join(coin.into_balance());
    }

    // === Owner Functions ===

    #[allow(lint(share_owned))]
    public entry fun initialize_data(
        self: &mut WaterCooler,
        waterCoolerAdminCap: &WaterCoolerAdminCap,
        mut numbers: vector<u64>,
        mut image_urls: vector<String>,
        mut keys: vector<vector<String>>,
        mut values: vector<vector<String>>,
        _: &mut TxContext,
    ) {
        assert!(self.is_initialized == false, EWaterCoolerAlreadyInitialized);
        assert!(waterCoolerAdminCap.`for` == object::id(self), EWaterCoolerCapMissMatch);
        self.init_counter = self.init_counter + 1;
        assert!(self.is_initialized, EWaterCoolerAlreadyInitilized);

        while (image_urls.length() > 0) {
            let number = numbers.pop_back();
            assert!(number <= self.supply, EInvalidnftNumber);

            let image_url = image_urls.pop_back();

            let key = keys.pop_back();
            let value = values.pop_back();            

            let already_added = self.num_to_image.contains(number);

            if(already_added == false) {
                self.remaining.push_back(number);
                self.nft_nums_retrieved.add(number, false);
                self.num_to_image.add(number, image_url);
                self.num_to_keys.add(number, key);
                self.num_to_values.add(number, value);
            }
        };

        // Initialize water cooler if the number of NFT created is equal to the size of the collection.
        if (self.init_counter == self.supply) {
            self.is_initialized = true;
        };
        self.deconstruct()
    }
    
    public entry fun set_treasury(
        self: &mut WaterCooler,
        waterCoolerAdminCap: &WaterCoolerAdminCap,
        treasury: address
    ) {
        assert!(waterCoolerAdminCap.`for` == object::id(self), EWaterCoolerCapMissMatch);
        self.treasury = treasury;
        self.deconstruct()
    }

    public entry fun set_price(
        self: &mut WaterCooler,
        waterCoolerAdminCap: &WaterCoolerAdminCap,
        price: u64
    ) {
        assert!(waterCoolerAdminCap.`for` == object::id(self), EWaterCoolerCapMissMatch);
        assert!(price >= 0, EInvalidPrice);
        self.price = price;
        self.deconstruct()
    }

    public entry fun set_status(
        self: &mut WaterCooler,
        waterCoolerAdminCap: &WaterCoolerAdminCap,
        status: u8
    ) {
        assert!(waterCoolerAdminCap.`for` == object::id(self), EWaterCoolerCapMissMatch);
        assert!(status == MINT_STATE_INACTIVE || status == MINT_STATE_ACTIVE, EInvalidStatusNumber);
        self.status = status;
        self.deconstruct()
    }
    
    public entry fun set_phase(
        self: &mut WaterCooler,
        waterCoolerAdminCap: &WaterCoolerAdminCap,
        phase: u8
    ) {
        assert!(waterCoolerAdminCap.`for` == object::id(self), EWaterCoolerCapMissMatch);
        assert!(phase >= 1 && phase <= 3, EInvalidPhaseNumber);
        self.phase = phase;
        self.deconstruct()
    }

    public entry fun claim_balance(
        self: &mut WaterCooler,
        waterCoolerAdminCap: &WaterCoolerAdminCap,
        ctx: &mut TxContext
    ) {
        assert!(waterCoolerAdminCap.`for` == object::id(self), EWaterCoolerCapMissMatch);
        let value = self.balance.value();
        let coin = coin::take(&mut self.balance, value, ctx);
        transfer::public_transfer(coin, self.treasury);
    }

    // === Package assert functions ===

    // This function is used to create the NFTs when a user mints
    public(package) fun get_metadata(
        self: &mut WaterCooler,
        ctx: &mut TxContext
    ): (u64, &String, &vector<String>, &vector<String>) {
        let index = if (self.remaining.length() == 1) {
                0
            } else {
                pseudo_random::rng(0, self.remaining.length() - 1, ctx)
            };

        let number = self.remaining.swap_remove(index);

        (number,
        self.num_to_image.borrow(number),
        self.num_to_keys.borrow(number),
        self.num_to_values.borrow(number))
    }

    public(package) fun checkWaterCoolerCap(
        self: &WaterCooler,
        cap: &WaterCoolerAdminCap,
        ) {
        assert!(cap.`for` == object::id(self), EWaterCoolerCapMissMatch);
    }

    // === Package view functions ===
    
    #[allow(unused_variable)]
    public(package) fun deconstruct(self: &WaterCooler) {
        let WaterCooler {
            id,
            name,
            description,
            image_url,
            ticket_image_url,
            treasury,
            supply,
            owner,
            is_initialized,
            init_counter,
            balance,
            remaining,
            nft_nums_retrieved,
            num_to_image,
            num_to_keys,
            num_to_values,
            retrieve_couter,
            price,
            phase,
            status,
            display,
            mint_fee
            } = self;
    }
    
    public(package) fun uid_mut(self: &mut WaterCooler): &mut UID {
        &mut self.id
    }

    public(package) fun price(self: &WaterCooler): u64 {
        self.price
    }

    public(package) fun phase(self: &WaterCooler): u8 {
        self.phase
    }

    public(package) fun status(self: &WaterCooler): u8 {
        self.status
    }

    public fun name(self: &WaterCooler): String {
        self.name
    }
    
    public fun description(self: &WaterCooler): String {
        self.description
    }
    
    public fun image_url(self: &WaterCooler): String {
        self.image_url
    }

    public fun is_initialized(self: &WaterCooler): bool {
        self.is_initialized
    }

    public fun treasury(self: &WaterCooler): address {
        self.treasury
    }

    public fun supply(self: &WaterCooler): u64 {
        self.supply
    }
    
    public fun placeholder_image(self: &WaterCooler): String {
        self.ticket_image_url
    }
    
    public fun owner(self: &WaterCooler): address {
        self.owner
    }
    
    public fun mint_fee(self: &WaterCooler): u64 {
        self.mint_fee
    }

    // === Test Functions ===

    #[test_only]
    public fun init_for_water(ctx: &mut TxContext) {
        init(WATER_COOLER {}, ctx);
    }
}
