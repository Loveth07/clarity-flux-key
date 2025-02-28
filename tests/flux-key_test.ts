import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain unchanged]

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
    
    block = chain.mineBlock([
      Tx.contractCall("flux-key", "get-key",
        [types.uint(keyId)],
        wallet_1.address
      )
    ]);
    assertEquals(block.receipts[0].result.includes(updatedData), true);
  },
});
