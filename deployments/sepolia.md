## Deployments

### command:

```bash
forge create --rpc-url <redacted> \
    --<deployer wallet redacted> \
    --etherscan-api-key <redacted> \
    --verify src/ownerOf_Art.sol:OwnerOf_Art \
    --libraries src/lib/BytecodeStorageV1Fork.sol:BytecodeStorageReader:0x478aC182d2B7902169a13fcD8A6a2fF885B4cEB5
```

Deployed to contract address: `0xc9bb9FEC6F4F673444a0Bc6dCA0DbB42604E0667`

Verify the contract on etherscan

```bash
forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --etherscan-api-key <redacted> \
    --compiler-version v0.8.21 \
    0xc9bb9FEC6F4F673444a0Bc6dCA0DbB42604E0667 \
    src/OwnerOf_Art.sol:OwnerOf_Art \
    --libraries src/lib/BytecodeStorageV1Fork.sol:BytecodeStorageReader:0x478aC182d2B7902169a13fcD8A6a2fF885B4cEB5
```
