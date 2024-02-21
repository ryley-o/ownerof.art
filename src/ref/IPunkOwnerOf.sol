// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IPunkOwnerOf
 * @dev Interface for CryptoPunks contract substitute for ownerOf function
 */
interface IPunkOwnerOf {
    // CryptoPunks use public mapping (uint256 => address) public punkIndexToAddress
    // instead of the ERC721 standard function ownerOf(uint256 tokenId) public view returns (address)
    function punkIndexToAddress(uint256 tokenId) external view returns (address);
}