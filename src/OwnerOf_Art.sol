// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {BytecodeStorageReader, BytecodeStorageWriter} from "lib/artblocks-contracts/packages/contracts/contracts/libs/v0.8.x/BytecodeStorageV1.sol";
import {IDelegateRegistry} from "lib/delegate-registry/src/IDelegateRegistry.sol";

import {IOwnerOf_Art} from "src/IOwnerOf_Art.sol";

/**
 * @title OwnerOf_Art
 * @author ryley.eth (ryley-o.eth)
 * @notice Contract for posting and retrieving messages about ERC721 tokens from their owners.
 * Messages are intended to be used for provenance and attribution of art and other digital assets.
 * Messages are stored in bytecode storage and may never be deleted or modified, but new messages may be posted.
 * The contract is integrated with delegate.xyz v2 to allow owners to delegate posting messages to others.
 */
contract OwnerOf_Art is IOwnerOf_Art, ReentrancyGuard {
    using BytecodeStorageWriter for string;
    using BytecodeStorageReader for address;
    
    mapping (address tokenAddress => mapping(uint tokenId => Message[])) private _messages;

    // integrate with delegate.xyz v2
    address public DELEGATE_REGISTRY = 0x00000000000000447e69651d841bD8D104Bed493;

    constructor() ReentrancyGuard() {}

    /**
     * @notice Post a new message about an ERC721 token.
     * The function will revert if the sender is not the owner of the token or a delegate of the owner on delegate.xyz v2.
     * The message is stored in bytecode storage and the address of the storage contract is emitted in the MessagePosted event.
     * The message may never be deleted or modified, but new messages may be posted.
     * @dev Reentrant calls are prevented by the ReentrancyGuard modifier
     * @param tokenAddress Address of the ERC721 token contract being posted about
     * @param tokenId ID of the token being posted about
     * @param message Message to be posted about the token
     */
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
        emit MessagePosted({tokenAddress: tokenAddress, tokenId: tokenId, owner: tokenOwner, bytecodeStorageAddress: bytecodeStorageAddress);
    }

    /**
     * @notice Get all messages posted about an ERC721 token.
     * @dev This function is gas unbounded and should be used with caution. For pagination, use getMessageAtIndex.
     * @param tokenAddress Address of the ERC721 token contract posted about
     * @param tokenId ID of the token posted about
     * @return messagesView Array of MessageView structs containing the messages posted about the token
     */
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

    /**
     * @notice Get the number of messages posted about an ERC721 token.
     * @param tokenAddress Address of the ERC721 token contract posted about
     * @param tokenId ID of the token posted about
     * @return count Number of messages posted about the token
     */
    function getMessageCount(address tokenAddress, uint256 tokenId) external view returns (uint256) {
        return _messages[tokenAddress][tokenId].length;
    }

    /**
     * @notice Get a message posted about an ERC721 token at a specific index.
     * Reverts if the index is out of bounds.
     * @param tokenAddress Address of the ERC721 token contract posted about
     * @param tokenId ID of the token posted about
     * @param index Index of the message to retrieve
     * @return messageView MessageView struct containing the message posted about the token
     */
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
