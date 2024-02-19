// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {BytecodeStorageReader, BytecodeStorageWriter} from "lib/artblocks-contracts/packages/contracts/contracts/libs/v0.8.x/BytecodeStorageV1.sol";

contract OwnerOf_Art {
    using BytecodeStorageWriter for string;
    using BytecodeStorageReader for address;
    
    mapping (address tokenAddress => mapping(uint tokenId => Message[])) private _messages;

    // integrate with delegate.xyz v2
    address public DELEGATION_REGISTRY = 0x00000000000000447e69651d841bD8D104Bed493;

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

    function postMessage(address tokenAddress, uint256 tokenId, string memory message) public {
        // write message to bytecode storage, push to messages array
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
            // check delegation registry
IDelegateRegistry(DELEGATE_REGISTRY).checkDelegateForERC721(
                msg.sender,
                tokenOwner,
                address(ORIGINAL_CONTRACT),
                tokenId,
                ""
            );

            // send message to owner
            // emit event
        }

    }

    function getMessages(address tokenAddress, uint256 tokenId) public view returns (MessageView[] memory) {
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

    function getMessageAtIndex(address tokenAddress, uint256 tokenId, uint256 index) public view returns (MessageView memory) {
        Message storage message = _messages[tokenAddress][tokenId][index];
        return MessageView({
            bytecodeStorageAddress: message.bytecodeStorageAddress,
            sender: message.sender,
            timestamp: message.timestamp,
            message: message.bytecodeStorageAddress.readFromBytecode()
        });
    }

    function getMessageCount(address tokenAddress, uint256 tokenId) public view returns (uint256) {
        return _messages[tokenAddress][tokenId].length;
    }
}
