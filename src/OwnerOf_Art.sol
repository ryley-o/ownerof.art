// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {BytecodeStorageReader, BytecodeStorageWriter} from "node_modules/@artblocks/contracts/contracts/libs/v0.8.x/BytecodeStorageV1.sol";

contract OwnerOf_Art {
    using BytecodeStorageWriter for string;
    using BytecodeStorageReader for address;
    
    mapping (address tokenAddress => mapping(uint tokenId => Message[])) private _messages;

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
        // gate to owner of token

        // write message to bytecode storage, push to messages array
        address bytecodeStorageAddress = message.writeToBytecode();
        _messages[tokenAddress][tokenId].push( Message({
            bytecodeStorageAddress: bytecodeStorageAddress,
            sender: msg.sender,
            timestamp: uint40(block.timestamp)
        }) );
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
