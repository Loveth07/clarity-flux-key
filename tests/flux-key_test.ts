import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can store and retrieve key",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const keyId = 1;
    const keyData = "encrypted:testkey123";
    
    let block = chain.mineBlock([
      Tx.contractCall("flux-key", "store-key", 
        [types.uint(keyId), types.utf8(keyData)], 
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
    assertEquals(block.receipts[0].result.includes(keyData), true);
  },
});

Clarinet.test({
  name: "Ensure can share key and recipient can access",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    const keyId = 2;
    const keyData = "encrypted:testkey456";
    
    let block = chain.mineBlock([
      Tx.contractCall("flux-key", "store-key",
        [types.uint(keyId), types.utf8(keyData)],
        wallet_1.address
      ),
      Tx.contractCall("flux-key", "share-key",
        [types.uint(keyId), types.principal(wallet_2.address), types.bool(true), types.bool(false)],
        wallet_1.address
      )
    ]);
    assertEquals(block.receipts[1].result, "(ok true)");
    
    block = chain.mineBlock([
      Tx.contractCall("flux-key", "get-key",
        [types.uint(keyId)],
        wallet_2.address
      )
    ]);
    assertEquals(block.receipts[0].result.includes(keyData), true);
  },
});
