module test_address::layerzero_test {

    use std::signer;
    use bridge::coin_bridge::{send_coin_from, quote_fee};

    struct Metadata has key {
        admin: address,
    }

    public entry fun initialize(admin: &signer) {
        move_to(admin, Metadata {
            admin: signer::address_of(admin),
        });
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
    ) {
        send_coin_from<CoinType>(
            sender,
            dst_chain_id,
            dst_receiver,
            amount_ld,
            native_fee,
            zro_fee,
            unwrap,
            adapter_params,
            msglib_params
        );
    }
}
