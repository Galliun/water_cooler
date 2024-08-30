#[test_only]
module galliun::test_og_mint {
    // === Imports ===
    use sui::{
        test_scenario::{Self as ts, next_tx},
        coin::{Self, Coin},
        sui::SUI,
        test_utils::{assert_eq},
        kiosk::{Self},
        transfer_policy::{TransferPolicy}
    };
    use std::string::{Self, String};
    use galliun::{
        helpers::{init_test_helper},
        water_cooler::{Self, WaterCooler, WaterCoolerAdminCap},
        capsule::{Capsule},
        cooler_factory::{Self, CoolerFactory, FactoryOwnerCap},
        orchestrator::{Self, WhitelistTicket, OrchAdminCap, OrchCap, OriginalGangsterTicket},
        attributes::{Self, Attributes},
        warehouse::{Self, Warehouse, WarehouseAdminCap},
        collection::{Collection},
        registry::{Registry},
        image::{Self, Image},
        settings::{Settings},
        factory_settings::{FactorySetings}
    };

    // === Constants ===
    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    // const TEST_ADDRESS2: address = @0xC;

    // === Test functions ===
    #[test]
    public fun test_water_cooler() {

        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        
        // User has to buy water_cooler from cooler_factory share object. 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut cooler_factory = ts::take_shared<CoolerFactory>(scenario);
            let coin_ = coin::mint_for_testing<SUI>(100_000_000, ts::ctx(scenario));
            
            let name = b"watercoolername".to_string();
            let description = b"some desc".to_string();
            let image_url = b"https://media.nfts.photos/nft.jpg".to_string();
            let placeholder_image_url = b"https://media.nfts.photos/placeholder.jpg".to_string();
            let supply = 150;

            cooler_factory::buy_water_cooler(
                &mut cooler_factory,
                coin_,
                name,
                description,
                image_url,
                placeholder_image_url,
                supply,
                TEST_ADDRESS1,
                ts::ctx(scenario)
            );

            ts::return_shared(cooler_factory);
        };

        // init WaterCooler. the number count to 1. So it is working. 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut water_cooler = ts::take_shared<WaterCooler>(scenario);
            let water_cooler_admin_cap = ts::take_from_sender<WaterCoolerAdminCap>(scenario);
            let mut registry = ts::take_from_sender<Registry>(scenario);
            let collection = ts::take_from_sender<Collection>(scenario);

            water_cooler::initialize_water_cooler(&water_cooler_admin_cap, &mut water_cooler, &mut registry, &collection, ts::ctx(scenario));

            ts::return_shared(water_cooler);
            ts::return_to_sender(scenario, collection);
            ts::return_to_sender(scenario, registry);
            ts::return_to_sender(scenario, water_cooler_admin_cap);
        };
 
        // we can push MizuNFT into the warehouse
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mint_cap = ts::take_from_sender<OrchAdminCap>(scenario);
            let water_cooler = ts::take_shared<WaterCooler>(scenario);
            let mut mint_warehouse = ts::take_shared<Warehouse>(scenario);
            let nft = ts::take_from_sender<Capsule>(scenario);
            let mut vector_mizu = vector::empty<Capsule>();
            vector_mizu.push_back(nft);

            orchestrator::stock_warehouse(
                &mint_cap,
                &water_cooler,
                vector_mizu,
                &mut mint_warehouse
            );
            // the nft's length should be equal to 1 
            assert_eq(orchestrator::get_mintwarehouse_length(&mint_warehouse), 1);
    
            ts::return_to_sender(scenario, mint_cap);
            ts::return_shared(mint_warehouse);
            ts::return_shared(water_cooler);
        };
        // set mint_price and status
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mint_cap = ts::take_from_sender<OrchAdminCap>(scenario);
            let mut mint_settings = ts::take_shared<Settings>(scenario);
            let price: u64 = 1_000_000_000;
            let status: u8 = 1;
            let phase: u8 = 1;

            orchestrator::set_mint_price(&mint_cap, &mut mint_settings, price);
            orchestrator::set_mint_status(&mint_cap, &mut mint_settings, status);
            orchestrator::set_mint_phase(&mint_cap, &mut mint_settings, phase);

            ts::return_to_sender(scenario, mint_cap);
      
            ts::return_shared(mint_settings);
        };

        // we must create WhitelistTicket 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mint_cap = ts::take_from_sender<OrchAdminCap>(scenario);
            let mint_warehouse = ts::take_shared<WaterCooler>(scenario);
            orchestrator::create_og_ticket(&mint_cap, &mint_warehouse, TEST_ADDRESS1, ts::ctx(scenario));
            ts::return_to_sender(scenario, mint_cap);
            ts::return_shared(mint_warehouse);
        };

        // we can do whitelist_mint 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let settings = ts::take_shared<Settings>(scenario);
            let mut warehouse = ts::take_shared<Warehouse>(scenario);
            let factory_settings = ts::take_shared<FactorySetings>(scenario);
            let water_cooler = ts::take_shared<WaterCooler>(scenario);
            let ticket = ts::take_from_sender<OriginalGangsterTicket>(scenario);
            let coin_ = coin::mint_for_testing<SUI>(1_000_000_000, ts::ctx(scenario));

            orchestrator::og_mint(
                ticket,
                &factory_settings,
                  &water_cooler,
                  &mut warehouse,
                  &settings,
                   coin_,
                    ts::ctx(scenario));
            
            ts::return_shared(warehouse);
            ts::return_shared(settings);
            ts::return_shared(water_cooler);
            ts::return_shared(factory_settings);
        };
        ts::end(scenario_test);
    }
}