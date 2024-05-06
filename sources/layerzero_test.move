module galnt_address::layerzero_test {

    use std::signer;
    use aptos_framework::account;
    use aptos_framework::aptos_account::transfer_coins;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::resource_account;

    use bridge::coin_bridge::{quote_fee, send_coin_from};

    const DEFAULT_ADMIN: address = @galnt_default_admin;
    const RESOURCE_ACCOUNT: address = @galnt_address;
    const DEV: address = @galnt_dev;

    const ADMIN_FEE_PERCENTAGE: u64 = 1000; // mean 10 percent

    // errors
    const ERROR_ONLY_ADMIN: u64 = 0;
    const ERROR_DIVIDE_BY_ZERO: u64 = 1;

    struct MetaData has key {
        signer_cap: account::SignerCapability,
        admin: address,
    }

    fun init_module(sender: &signer) {
        let signer_cap = resource_account::retrieve_resource_account_cap(sender, DEV);
        let resource_signer = account::create_signer_with_capability(&signer_cap);

        move_to(&resource_signer, MetaData {
            signer_cap,
            admin: DEFAULT_ADMIN,
        });
    }

    public entry fun set_admin(sender: &signer, new_admin: address) acquires MetaData {
        let sender_addr = signer::address_of(sender);
        let metadata = borrow_global_mut<MetaData>(RESOURCE_ACCOUNT);

        //only admin can assign new admin
        assert!(sender_addr == metadata.admin, ERROR_ONLY_ADMIN);
        metadata.admin = new_admin;
    }

    #[view]
    public fun quote_fee_evm(
        dst_chain_id: u64,
        pay_in_zro: bool,
        adapter_params: vector<u8>,
        msglib_params: vector<u8>
    ): (u64, u64) {
        let (native_fee, zro_fee) = quote_fee(dst_chain_id, pay_in_zro, adapter_params, msglib_params);
        (native_fee, zro_fee)
    }

    public entry fun send_coin_from_aptos<CoinType>(
        sender: &signer,
        dst_chain_id: u64,
        dst_receiver: vector<u8>,
        amount_ld: u64,
        native_fee: u64,
        zro_fee: u64,
        unwrap: bool,
        adapter_params: vector<u8>,
        msglib_params: vector<u8>,
    ) acquires MetaData {
        let metadata = borrow_global_mut<MetaData>(RESOURCE_ACCOUNT);

        //calculating admin fee
        let admin_fee = mul_div(amount_ld, ADMIN_FEE_PERCENTAGE, 10000);
        let amount_after_fee = amount_ld - admin_fee;

        transfer_coins<CoinType>(sender, metadata.admin, admin_fee);
        transfer_coins<CoinType>(sender, RESOURCE_ACCOUNT, amount_after_fee);
        transfer_coins<AptosCoin>(sender, RESOURCE_ACCOUNT, native_fee);

        let resource_signer = account::create_signer_with_capability(&metadata.signer_cap);
        send_coin_from<CoinType>(
            &resource_signer,
            dst_chain_id,
            dst_receiver,
            amount_after_fee,
            native_fee,
            zro_fee,
            unwrap,
            adapter_params,
            msglib_params
        );
    }

    /// Implements: `x` * `y` / `z`.
    public fun mul_div(x: u64, y: u64, z: u64): u64 {
        assert!(z != 0, ERROR_DIVIDE_BY_ZERO);
        let r = (x as u128) * (y as u128) / (z as u128);
        (r as u64)
    }
}
