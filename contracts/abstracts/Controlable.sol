// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/access/AccessControl.sol';

interface IERC20 {
  function balanceOf(address account) external returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);
}

abstract contract Controlable is AccessControl {
  bytes32 public constant MODERATOR_ROLE = keccak256('MODERATOR_ROLE');
  bytes32 public constant TREASURY_ROLE = keccak256('TREASURY_ROLE');

  IERC20 private _token;

  mapping(address => mapping(uint => bool)) private blacklistToken;
  mapping(address => bool) private blacklistUser;
  mapping(address => bool) private supportedContracts;

  uint32 private _transactionFee; // 100_000 = 1%
  uint256 private _accumulatedTransactionFee;

  event TransactionFeeChanged(uint32 indexed oldFee, uint32 indexed newFee);
  event SupportedContractRemoved(address indexed contractAddress);
  event SupportedContractAdded(address indexed contractAddress);

  modifier onlyAdmin() {
    require(isAdmin(msg.sender), 'Controlable: Only admin');
    _;
  }

  function _changeSupportedContract(address contractAddress) internal returns (bool success) {
    if (supportedContracts[contractAddress]) {
      // Le contrat est déjà pris en charge, donc on le supprime
      supportedContracts[contractAddress] = false;
      emit SupportedContractRemoved(contractAddress);
    } else {
      // Le contrat n'est pas pris en charge, donc on l'ajoute
      supportedContracts[contractAddress] = true;
      emit SupportedContractAdded(contractAddress);
    }
    return true;
  }

  function _changeTransactionFee(uint32 transactionFee_) internal returns (bool success) {
    uint32 oldFee = _transactionFee;
    _transactionFee = transactionFee_;
    emit TransactionFeeChanged(oldFee, transactionFee_);
    return true;
  }

  // Treasury
  function _withdrawTransactionFee() internal returns (bool success) {
    require(_token.transfer(msg.sender, _accumulatedTransactionFee), 'Controlable: Transfer failed');
    return true;
  }

  // Moderator
  function _blacklistToken(address tokenContract, uint256 tokenId, bool isBlacklisted) internal returns (bool success) {
    if (isBlacklisted == true) {
      blacklistToken[tokenContract][tokenId] = true;
    } else {
      blacklistToken[tokenContract][tokenId] = false;
    }
    success = true;
  }

  function _blacklistUser(address userAddress, bool set) internal returns (bool success) {
    if (set == true) {
      blacklistUser[userAddress] = true;
    } else {
      blacklistUser[userAddress] = false;
    }
  }

  function transactionFee() public returns (uint32) {
    return _transactionFee;
  }

  function token() public returns (address tokenAddress) {}

  function isAdmin(address account) public returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }

  function isTreasury(address account) public returns (bool) {
    return hasRole(TREASURY_ROLE, account);
  }

  function isModerator(address account) public returns (bool) {
    return hasRole(MODERATOR_ROLE, account);
  }
}
