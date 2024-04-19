module test_address::layerzero_test {

    use std::signer;
    use std::vector;
    use bridge::coin_bridge::{quote_fee, send_coin_from};

    struct Metadata has key {
        admin: address,
    }

    public entry fun initialize(admin: &signer) {
        move_to(admin, Metadata {
            admin: signer::address_of(admin),
        });
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
