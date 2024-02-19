// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {BytecodeStorageReader, BytecodeStorageWriter} from "lib/artblocks-contracts/packages/contracts/contracts/libs/v0.8.x/BytecodeStorageV1.sol";
import {IDelegateRegistry} from "lib/delegate-registry/src/IDelegateRegistry.sol";

import {IOwnerOf_Art} from "src/IOwnerOf_Art.sol";

contract OwnerOf_Art is IOwnerOf_Art, ReentrancyGuard {
    using BytecodeStorageWriter for string;
    using BytecodeStorageReader for address;
    
    mapping (address tokenAddress => mapping(uint tokenId => Message[])) private _messages;

    // integrate with delegate.xyz v2
    address public DELEGATE_REGISTRY = 0x00000000000000447e69651d841bD8D104Bed493;

    constructor() ReentrancyGuard() {}

    function postMessage(address tokenAddress, uint256 tokenId, string memory message) external nonReentrant {
        // EFFECTS
        // write message to bytecode storage, push to messages storage array
        address bytecodeStorageAddress = message.writeToBytecode();
        _messages[tokenAddress][tokenId].push( Message({
            bytecodeStorageAddress: bytecodeStorageAddress,
            sender: msg.sender,
            timestamp: uint40(block.timestamp)
        }) );

        // INTERACTIONS
        // gate to owner of token
        address tokenOwner = IERC721(tokenAddress).ownerOf(tokenId);
        if (tokenOwner != msg.sender) {
            // check delegate.xyz v2
            bool isDelegate = IDelegateRegistry(DELEGATE_REGISTRY).checkDelegateForERC721({
                to: msg.sender,
                from: tokenOwner,
                contract_: address(tokenAddress),
                tokenId: tokenId,
                rights: ""
            });
            require(isDelegate, "OwnerOf_Art: not owner or delegate");
        }

        // EVENTS
        emit MessagePosted(tokenAddress, tokenId, bytecodeStorageAddress, msg.sender);

    }

    // @dev getMessages gas unbounded, use with caution, or use getMessageAtIndex for pagination
    function getMessages(address tokenAddress, uint256 tokenId) external view returns (MessageView[] memory) {
        Message[] storage messages = _messages[tokenAddress][tokenId];
        uint256 messagesLength = messages.length;
        MessageView[] memory messagesView = new MessageView[](messagesLength);
        for (uint256 i = 0; i < messagesLength; i++) {
            Message storage message = messages[i];
            messagesView[i] = MessageView({
                bytecodeStorageAddress: message.bytecodeStorageAddress,
                sender: message.sender,
                timestamp: message.timestamp,
                message: message.bytecodeStorageAddress.readFromBytecode()
            });
        }
        return messagesView;
    }

    function getMessageCount(address tokenAddress, uint256 tokenId) external view returns (uint256) {
        return _messages[tokenAddress][tokenId].length;
    }

    function getMessageAtIndex(address tokenAddress, uint256 tokenId, uint256 index) external view returns (MessageView memory) {
        Message storage message = _messages[tokenAddress][tokenId][index];
        return MessageView({
            bytecodeStorageAddress: message.bytecodeStorageAddress,
            sender: message.sender,
            timestamp: message.timestamp,
            message: message.bytecodeStorageAddress.readFromBytecode()
        });
    }
}
