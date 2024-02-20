// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {BytecodeStorageReader, BytecodeStorageWriter} from "lib/artblocks-contracts/packages/contracts/contracts/libs/v0.8.x/BytecodeStorageV1.sol";
import {IDelegateRegistry} from "lib/delegate-registry/src/IDelegateRegistry.sol";

interface IOwnerOf_Art {
    /**
     * Message posted event emitted when a message is posted about an ERC721 token by its owner (or delegate)
     * @param tokenAddress Address of the ERC721 token contract being posted about
     * @param tokenId ID of the token being posted about
     * @param owner Address of the owner of the token sending the message
     * @param bytecodeStorageAddress Address of the bytecode storage contract where the message is stored
     */
    event MessagePosted(address indexed tokenAddress, uint256 indexed tokenId, address indexed owner, address bytecodeStorageAddress, uint256 index);

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

    /**
     * @dev DELEGATE_REGISTRY is the address of the Delegate Registry contract
     */
    function DELEGATE_REGISTRY() external view returns (address);

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
    function postMessage(address tokenAddress, uint256 tokenId, string memory message) external;

    /**
     * @notice Get all messages posted about an ERC721 token.
     * @dev This function is gas unbounded and should be used with caution. For pagination, use getMessageAtIndex.
     * @param tokenAddress Address of the ERC721 token contract posted about
     * @param tokenId ID of the token posted about
     * @return messagesView Array of MessageView structs containing the messages posted about the token
     */
    function getMessages(address tokenAddress, uint256 tokenId) external view returns (MessageView[] memory);

    /**
     * @notice Get the number of messages posted about an ERC721 token.
     * @param tokenAddress Address of the ERC721 token contract posted about
     * @param tokenId ID of the token posted about
     * @return count Number of messages posted about the token
     */
    function getMessageCount(address tokenAddress, uint256 tokenId) external view returns (uint256);

    /**
     * @notice Get a message posted about an ERC721 token at a specific index.
     * Reverts if the index is out of bounds.
     * @param tokenAddress Address of the ERC721 token contract posted about
     * @param tokenId ID of the token posted about
     * @param index Index of the message to retrieve
     * @return messageView MessageView struct containing the message posted about the token
     */
    function getMessageAtIndex(address tokenAddress, uint256 tokenId, uint256 index) external view returns (MessageView memory);
}
