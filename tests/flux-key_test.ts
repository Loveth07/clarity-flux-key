import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can update key with proper authorization",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const keyId = 3;
    const keyData = "encrypted:initial";
    const updatedData = "encrypted:updated";
    
    let block = chain.mineBlock([
      Tx.contractCall("flux-key", "store-key",
        [
          types.uint(keyId),
          types.utf8(keyData),
          types.some(types.utf8("Test Key")),
          types.some(types.utf8("Test Description"))
        ],
        wallet_1.address
      )
    ]);
    assertEquals(block.receipts[0].result, "(ok true)");
    
    block = chain.mineBlock([
      Tx.contractCall("flux-key", "update-key",
        [types.uint(keyId), types.utf8(updatedData)],
        wallet_1.address
      )
    ]);
    assertEquals(block.receipts[0].result, "(ok true)");
  },
});

Clarinet.test({
  name: "Ensure time-limited access works correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    const keyId = 4;
    const keyData = "encrypted:test";
    
    let block = chain.mineBlock([
      Tx.contractCall("flux-key", "store-key",
        [
          types.uint(keyId),
          types.utf8(keyData),
          types.some(types.utf8("Time Test")),
          types.some(types.utf8("Time Test Description"))
        ],
        wallet_1.address
      ),
      Tx.contractCall("flux-key", "share-key-timed",
        [
          types.uint(keyId),
          types.principal(wallet_2.address),
          types.bool(true),
          types.bool(false),
          types.uint(10)
        ],
        wallet_1.address
      )
    ]);
    assertEquals(block.receipts[1].result, "(ok true)");
  },
});
