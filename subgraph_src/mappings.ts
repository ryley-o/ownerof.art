// standard library
import { BigInt, log, Address } from "@graphprotocol/graph-ts";
// events
import {
  MessagePosted,
  IOwnerOf_Art,
} from "../generated/IOwnerOfArt/IOwnerOf_Art";
import { IERC721Metadata } from "../generated/IOwnerOfArt/IERC721Metadata";
// entities
import { Token, Contract, Message } from "../generated/schema";

// ------ EVENT HANDLERS ------

export function handleMessagePosted(event: MessagePosted): void {
  // get or create the contract
  const contract = getOrCreateContract(
    event.params.tokenAddress,
    event.block.timestamp
  );
  // get or create the token
  const token = getOrCreateToken(
    event.params.tokenAddress,
    event.params.tokenId,
    event.block.timestamp
  );
  // create and save the message
  const messageEntityId = getMessageEntityId(
    event.params.tokenAddress,
    event.params.tokenId,
    event.params.index
  );
  let message = new Message(messageEntityId);
  message.contract = contract.id;
  message.token = token.id;
  message.index = event.params.index;
  message.owner = event.params.owner;
  message.message = getMessageString(
    event.params.tokenAddress,
    token.tokenId,
    event.params.index
  );
  message.bytecodeAddress = event.params.bytecodeStorageAddress;
  message.blockNumber = event.block.number;
  message.timestamp = event.block.timestamp;

  message.save();
}

// ------ HELPER FUNCTIONS ------

// This function is used to get or create a Contract entity
function getOrCreateContract(address: Address, timestamp: BigInt): Contract {
  const contractEntityId = getContractEntityId(address);
  let contract = Contract.load(contractEntityId);
  if (contract) {
    return contract;
  }
  // contract not found - initialize contract entity and save
  contract = new Contract(contractEntityId);
  contract.address = address;
  contract.name = getContractName(address);
  contract.symbol = getContractSymbol(address);
  contract.updatedAt = timestamp;
  contract.save();

  return contract;
}

// This function is used to try and get a contract's name
function getContractName(address: Address): string {
  let erc721Metadata = IERC721Metadata.bind(address);
  let name = erc721Metadata.try_name();
  return name.reverted ? "Unknown" : name.value;
}

// This function is used to try and get a contract's symbol
function getContractSymbol(address: Address): string {
  let erc721Metadata = IERC721Metadata.bind(address);
  let symbol = erc721Metadata.try_symbol();
  return symbol.reverted ? "UNKNOWN" : symbol.value;
}

// This function is used to get or create a Token entity
function getOrCreateToken(
  address: Address,
  tokenId: BigInt,
  timestamp: BigInt
): Token {
  const contract = getOrCreateContract(address, timestamp);
  const tokenEntityId = getTokenEntityId(address, tokenId);
  let token = Token.load(tokenEntityId);
  if (token) {
    return token;
  }
  // token not found - initialize token entity and save
  token = new Token(tokenEntityId);
  token.contract = contract.id;
  token.tokenId = tokenId;
  token.updatedAt = timestamp;
  token.save();

  return token;
}

// this function is used to get the message text of a given post
function getMessageString(
  contractAddress: Address,
  tokenId: BigInt,
  index: BigInt
): string {
  let iOwnerOfArt = IOwnerOf_Art.bind(contractAddress);
  let message = iOwnerOfArt.try_getMessageAtIndex(
    contractAddress,
    tokenId,
    index
  );
  if (message.reverted) {
    // this should never happen, but log a warning just in case
    log.warning("Failed to get message at index {} for token {}", [
      index.toString(),
      tokenId.toString(),
    ]);
  }
  return message.reverted ? "ERROR" : message.value.message;
}

// ------ ENTITY ID FUNCTIONS ------

// This function returns a Token entity ID from relevant data
function getTokenEntityId(address: Address, tokenId: BigInt): string {
  return address.toHexString() + "-" + tokenId.toString();
}

function getContractEntityId(address: Address): string {
  return address.toHexString();
}

// This function returns a Message entity ID from relevant data
function getMessageEntityId(
  address: Address,
  tokenId: BigInt,
  index: BigInt
): string {
  return (
    address.toHexString() + "-" + tokenId.toString() + "-" + index.toString()
  );
}
