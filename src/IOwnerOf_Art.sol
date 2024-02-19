// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {BytecodeStorageReader, BytecodeStorageWriter} from "lib/artblocks-contracts/packages/contracts/contracts/libs/v0.8.x/BytecodeStorageV1.sol";
import {IDelegateRegistry} from "lib/delegate-registry/src/IDelegateRegistry.sol";

interface IOwnerOf_Art {
    event MessagePosted(address indexed tokenAddress, uint256 indexed tokenId, address indexed sender, address bytecodeStorageAddress);
    
    struct Message {
        address bytecodeStorageAddress;
        address sender;
        uint40 timestamp;
    }

    struct MessageView {
        address bytecodeStorageAddress;
        address sender;
        uint40 timestamp;
        string message;
    }

    function DELEGATE_REGISTRY() external view returns (address);

    function postMessage(address tokenAddress, uint256 tokenId, string memory message) external;

    // @dev getMessages gas unbounded, use with caution, or use getMessageAtIndex for pagination
    function getMessages(address tokenAddress, uint256 tokenId) external view returns (MessageView[] memory);

    function getMessageCount(address tokenAddress, uint256 tokenId) external view returns (uint256);

    function getMessageAtIndex(address tokenAddress, uint256 tokenId, uint256 index) external view returns (MessageView memory);
}
