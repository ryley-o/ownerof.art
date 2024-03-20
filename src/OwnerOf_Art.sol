// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IPunkOwnerOf} from "src/ref/IPunkOwnerOf.sol";
import {BytecodeStorageReader, BytecodeStorageWriter} from "./lib/BytecodeStorageV1Fork.sol";
import {IDelegateRegistry} from "lib/delegate-registry/src/IDelegateRegistry.sol";
import { LibZip } from "lib/solady/src/utils/LibZip.sol";

import {IOwnerOf_Art} from "src/IOwnerOf_Art.sol";

/**
 * @title OwnerOf_Art
 * @author ryley.eth (ryley-o.eth)
 * @notice Contract that enables posting of provenance messages from owners of ERC-721 tokens.
 * Messages are intended to be used for provenance of art and other digital assets.
 * Messages are stored in bytecode storage and may never be deleted or modified, but new messages may be posted.
 * The contract is integrated with delegate.xyz v2 to allow owners to delegate posting messages to others.
 * Only ERC-721 and cryptopunks tokens are supported.
 * The ERC-1155 standard is intentionally not supported in this contract to prevent one owner from posting
 * messages about another owner's token, potentially negatively impacting other owners' assets without their consent.
 */
contract OwnerOf_Art is IOwnerOf_Art, Ownable, ReentrancyGuard {
    using BytecodeStorageWriter for string;
    using BytecodeStorageWriter for bytes;
    using BytecodeStorageReader for address;

    // integrate with delegate.xyz v2
    // @dev this is consistent across multiple networks
    address public constant DELEGATE_REGISTRY = 0x00000000000000447e69651d841bD8D104Bed493;

    // override cryptopunks ownerOf function
    // @dev Ethereum mainnet only
    address private constant _CRYPTOPUNKS = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    
    mapping (address tokenAddress => mapping(uint tokenId => Message[])) private _messages;

    /**
     * Assign the initial owner of the contract, as well as initialize the ReentrancyGuard.
     * @dev The owner's only role is to drain tips or update the owner. No other functionality is restricted to the owner,
     * and the owner cannot affect the posting or storage of messages.
     * @param initialOwner Address to be set as the owner of the contract
     */
    constructor(address initialOwner) Ownable(initialOwner) ReentrancyGuard() {}

    /**
     * @notice Post a new message about an ERC721 token.
     * The function is payable to allow for tipping the owner of this contract for the service.
     * The function will revert if the sender is not the owner of the token or a delegate of the owner on delegate.xyz v2.
     * The message is stored in bytecode storage and the address of the storage contract is emitted in the MessagePosted event.
     * The message may never be deleted or modified, but new messages may be posted.
     * @dev Reentrant calls are prevented by the ReentrancyGuard modifier
     * @param tokenAddress Address of the ERC721 token contract being posted about
     * @param tokenId ID of the token being posted about
     * @param message Message to be posted about the token
     */
    function postMessage(address tokenAddress, uint256 tokenId, string memory message) external payable nonReentrant {
        // EFFECTS
        // write message to bytecode storage, push to messages storage array
        address bytecodeStorageAddress = message.writeToBytecode();
        _messages[tokenAddress][tokenId].push( Message({
            bytecodeStorageAddress: bytecodeStorageAddress,
            sender: msg.sender,
            timestamp: uint40(block.timestamp)
        }) );

        // INTERACTIONS
        _verifyOwnerOrDelegateAndEmitEvent({
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            bytecodeStorageAddress: bytecodeStorageAddress
        });
    }

    /**
     * @notice Post a new message about an ERC721 token.
     * The function is payable to allow for tipping the owner of this contract for the service.
     * The function will revert if the sender is not the owner of the token or a delegate of the owner on delegate.xyz v2.
     * The message is stored in bytecode storage and the address of the storage contract is emitted in the MessagePosted event.
     * The message may never be deleted or modified, but new messages may be posted.
     * @dev Reentrant calls are prevented by the ReentrancyGuard modifier
     * @param tokenAddress Address of the ERC721 token contract being posted about
     * @param tokenId ID of the token being posted about
     * @param messageCompressed Message to be posted about the token, compressed with flz compress.
     * Pure function getCompressedMessage may be used off-chain to compress a message prior to calling this function.
     */
    function postMessageCompressed(address tokenAddress, uint256 tokenId, bytes memory messageCompressed) external payable nonReentrant {
        // EFFECTS
        // write message to bytecode storage, push to messages storage array
        address bytecodeStorageAddress = messageCompressed.writeToBytecodeCompressed();
        _messages[tokenAddress][tokenId].push( Message({
            bytecodeStorageAddress: bytecodeStorageAddress,
            sender: msg.sender,
            timestamp: uint40(block.timestamp)
        }) );

        // INTERACTIONS
        _verifyOwnerOrDelegateAndEmitEvent({
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            bytecodeStorageAddress: bytecodeStorageAddress
        });
    }

    /**
     * Function to enable the owner to drain tips from the contract to a specified address.
     * Reverts if the caller is not the owner.
     * @param to Address to drain funds to
     */
    function drainTipsTo(address payable to) external onlyOwner {
        (bool success, ) = to.call{
            value: address(this).balance
        }("");
        require(success, "drain payment failed");
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

    /**
     * @notice Get the compressed form of a message string using flz compress. The compressed
     * form of the message may be used as the input to postMessageCompressed for a more gas efficient
     * way to post long messages.
     * @param message string to compress
     * @return bytes compressed form of the message
     */
    function getCompressedMessage(string memory message) external pure returns (bytes memory) {
        return LibZip.flzCompress(bytes(message));
    }

    /**
     * Verify that the sender is the owner of the token or a delegate of the owner on delegate.xyz v2.
     * If the sender is the owner or a delegate, emit a MessagePosted event.
     * Reverts if the sender is not the owner or a delegate of the owner on delegate.xyz v2.
     * @dev This function is used to avoid code duplication in the postMessage and postMessageCompressed functions.
     * @dev This function should be called within the context of a nonReentrant modifier.
     * @param tokenAddress Address of the ERC721 token contract being posted about
     * @param tokenId ID of the token being posted about
     * @param bytecodeStorageAddress Address of the bytecode storage contract where the message was stored
     */
    function _verifyOwnerOrDelegateAndEmitEvent(address tokenAddress, uint256 tokenId, address bytecodeStorageAddress) internal {
        // INTERACTIONS
        // gate to owner of token
        // @dev add support for cryptopunks non-standard ownerOf function
        address tokenOwner = (tokenAddress == _CRYPTOPUNKS && block.chainid == 1)
            ? IPunkOwnerOf(_CRYPTOPUNKS).punkIndexToAddress(tokenId)
            : IERC721(tokenAddress).ownerOf(tokenId);
        if (tokenOwner != msg.sender) {
            // check delegate.xyz v2
            bool isDelegate = IDelegateRegistry(DELEGATE_REGISTRY).checkDelegateForERC721({
                to: msg.sender,
                from: tokenOwner,
                contract_: address(this),
                tokenId: tokenId,
                rights: ""
            });
            require(isDelegate, "OwnerOf_Art: not owner or delegate");
        }

        // EVENTS
        emit MessagePosted({
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            owner: tokenOwner,
            bytecodeStorageAddress: bytecodeStorageAddress,
            index: _messages[tokenAddress][tokenId].length - 1,
            tip: msg.value
        });
    }
}
