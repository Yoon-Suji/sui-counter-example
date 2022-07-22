// Copyright (c) 2022, Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// This example demonstrates a basic use of a shared object.
/// Rules:
/// - anyone can create and share a counter
/// - everyone can increment a counter by 1
/// - the owner of the counter can reset it to any value
module my_first_package::counter {
    use sui::transfer;
    use sui::id::VersionedID;
    use sui::tx_context::{Self, TxContext};

    /// A shared counter.
    struct Counter has key {
        id: VersionedID,
        owner: address,
        count: u64
    }

    public fun owner(counter: &Counter): address {
        counter.owner
    }

    public fun get_count(counter: &Counter): u64 {
        counter.count
    }

    /// Create and share a Counter object.
    public entry fun create(ctx: &mut TxContext) {
        transfer::share_object(Counter {
            id: tx_context::new_id(ctx),
            owner: tx_context::sender(ctx),
            count: 0
        })
    }

    /// Increment a counter by 1.
    public entry fun increment(counter: &mut Counter, count: u64) {
        counter.count = counter.count + count;
    }

    public entry fun reset(counter: &mut Counter, count: u64) {
        counter.count = count;
    }

}

#[test_only]
module my_first_package::counter_test {
    use sui::test_scenario;
    use my_first_package::counter;

    #[test]
    fun test_counter() {
        let owner = @0xC0FFEE;
        let user1 = @0xA1;

        let scenario = &mut test_scenario::begin(&user1);

        test_scenario::next_tx(scenario, &owner);
        {
            counter::create(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, &user1);
        {
            let counter_wrapper = test_scenario::take_shared<counter::Counter>(scenario);
            let counter = test_scenario::borrow_mut(&mut counter_wrapper);

            assert!(counter::owner(counter) == owner, 0);
            assert!(counter::get_count(counter) == 0, 1);

            counter::increment(counter, 5);
            test_scenario::return_shared(scenario, counter_wrapper);
        };

        test_scenario::next_tx(scenario, &owner);
        {
            let counter_wrapper = test_scenario::take_shared<counter::Counter>(scenario);
            let counter = test_scenario::borrow_mut(&mut counter_wrapper);

            assert!(counter::owner(counter) == owner, 0);
            assert!(counter::get_count(counter) == 5, 1);

            counter::reset(counter, 100);

            test_scenario::return_shared(scenario, counter_wrapper);
        };

        test_scenario::next_tx(scenario, &user1);
        {
            let counter_wrapper = test_scenario::take_shared<counter::Counter>(scenario);
            let counter = test_scenario::borrow_mut(&mut counter_wrapper);

            assert!(counter::owner(counter) == owner, 0);
            assert!(counter::get_count(counter) == 100, 1);

            counter::increment(counter, 1);

            assert!(counter::get_count(counter) == 101, 2);

            test_scenario::return_shared(scenario, counter_wrapper);
        };
    }
}
