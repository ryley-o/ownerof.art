## Deployments

### command:
```bash
ownerof.art % forge create --rpc-url <redacted> \
    --<deployer wallet redacted> \
    --etherscan-api-key <redacted> \
    --verify src/ownerOf_Art.sol:OwnerOf_Art \
    --libraries lib/artblocks-contracts/packages/contracts/contracts/libs/v0.8.x/BytecodeStorageV1.sol:BytecodeStorageReader:0x7497909537cE00fDda93c12d5083D8647C593c67
```

Contract address: 0xF7961080CF6c58ea8558E7161A6E58EeA51eA952

Verify the contract on etherscan
```bash
forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --etherscan-api-key <redacted> \
    --compiler-version v0.8.21 \
    0xF7961080CF6c58ea8558E7161A6E58EeA51eA952 \
    src/OwnerOf_Art.sol:OwnerOf_Art \
    --libraries lib/artblocks-contracts/packages/contracts/contracts/libs/v0.8.x/BytecodeStorageV1.sol:BytecodeStorageReader:0x7497909537cE00fDda93c12d5083D8647C593c67
```