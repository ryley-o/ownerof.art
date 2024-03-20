# Deployment Summary

Deployments utilize the safe create2 factory at `0x0000000000FFe8B47B3e2130213B802212439497` to enable anyone to deploy to any evm chain.

A basic outline of the process is described and documented below.

## Initial BytecodeStorageV1Fork.sol:BytecodeStorageReader

deploy command:

```bash
forge create --rpc-url <redacted> \
    --private-key <redacted> \
    --etherscan-api-key <redacted \
    --verify src/lib/BytecodeStorageV1Fork.sol:BytecodeStorageReader
```

deployed to: `0xdE8C67f94f04A244807C7fB2eeebd95789933943`

verify command:

```bash
forge verify-contract --chain-id 11155111 --num-of-optimizations 200 --watch --etherscan-api-key <redacted> --compiler-version v0.8.21 0xdE8C67f94f04A244807C7fB2eeebd95789933943 src/lib/BytecodeStorageV1Fork.sol:BytecodeStorageReader
```

### create2 deployments

- anyone can deploy to any evm chain with safe create2 factory at `0x0000000000FFe8B47B3e2130213B802212439497`, salt `0x000000000000000000000000000000000000000052d1b126ddbe0987b1070050`, and the library is deployed to: `0x00000000Ff04094962DE55805fA85B4e67CF3b8E`

- verify with:

```bash
forge verify-contract --chain-id <chainId> --num-of-optimizations 200 --watch --etherscan-api-key <redacted> --compiler-version v0.8.21 0x00000000Ff04094962DE55805fA85B4e67CF3b8E src/lib/BytecodeStorageV1Fork.sol:BytecodeStorageReader
```

## Initial ownerOf_Art.sol:OwnerOf_Art

deploy command:

```bash
forge create --rpc-url <redacted> \
    --constructor-args 0x2A98FCD155c9Da4A28BdB32acc935836C233882A /
    --private-key <redacted> \
    --etherscan-api-key <redacted> \
    --verify src/OwnerOf_Art.sol:OwnerOf_Art \
    --libraries src/lib/BytecodeStorageV1Fork.sol:BytecodeStorageReader:0x00000000Ff04094962DE55805fA85B4e67CF3b8E
```

Deployed to contract address: `0x0C6d32e8d4A885c30D6A30734dF84040A1e5C311`

verify command:

```bash
forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address)" 0x2A98FCD155c9Da4A28BdB32acc935836C233882A) \
    --etherscan-api-key <redacted> \
    --compiler-version v0.8.21 \
    0x0C6d32e8d4A885c30D6A30734dF84040A1e5C311 \
    src/OwnerOf_Art.sol:OwnerOf_Art \
    --libraries src/lib/BytecodeStorageV1Fork.sol:BytecodeStorageReader:0x00000000Ff04094962DE55805fA85B4e67CF3b8E
```

### subsequent deployments

- anyone can deploy to any evm chain with safe create2 factory at `0x0000000000FFe8B47B3e2130213B802212439497`, salt `0x00000000000000000000000000000000000000009282e7db7fe7afc1ef3f0080`, and the library is deployed to: `0x0000000042aBB12Bc4935734b69f9745B803E076`

- verify with:

```bash
forge verify-contract --chain-id <chainId> --num-of-optimizations 200 --watch --constructor-args $(cast abi-encode "constructor(address)" 0x2A98FCD155c9Da4A28BdB32acc935836C233882A --etherscan-api-key <redacted> --compiler-version v0.8.21 0x0000000042aBB12Bc4935734b69f9745B803E076 src/OwnerOf_Art.sol:OwnerOf_Art --libraries src/lib/BytecodeStorageV1Fork.sol:BytecodeStorageReader:0x00000000Ff04094962DE55805fA85B4e67CF3b8E
```
