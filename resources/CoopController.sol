// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../lib/FixedPoint.sol";

import "./CoopItem.sol";
import "./CoopListing.sol";
import "./CoopVault.sol";
import "../tokens/H2OToken.sol";

contract CoopController {
    // Use Fixed Point library for decimal ints.
    using UFixedPoint for uint256;
    using SFixedPoint for int256;

    // *** State Variables *** //

    // The amount of each purcahse paid to the coop
    uint256 public coopTax;

    // The contract of the CoopItem contract.
    CoopItem public coopItem;

    // The contract of the CoopListing contract.
    CoopListing public coopListing;

    // the contract of the CoopVault contract.
    CoopVault public coopVault;

    // the H2O token contract
    H2OToken public h2oToken;

    // Admin of the coop contract
    address public admin;

    // Mapping of address allowed to create listings
    mapping(address => bool) public sellers;

    // *** Events *** //

    // Emitted when a listing is created.
    event ListingCreated(uint256 id, address owner, string name, string description, uint256 price, uint256 numberAvailable, uint256 expirationTime);

    // Emitted when an item is created.
    event ItemCreated(uint256 id, address owner, uint256 listingId, uint256 number);

    // Emitted when an item is fulfilled.
    event ItemSent(uint256 id);

    // Emitted when an item is received.
    event ItemReceived(uint256 id);

    // *** Constructor *** //

    /// @notice Constructor
    constructor() {
        admin = msg.sender;
        sellers[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function.");
        _;
    }

    modifier onlySeller() {
        require(sellers[msg.sender], "Only a listing creator can call this function.");
        _;
    }

    // *** Setters *** //

    // Change the admin
    function setCoopAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    // Set the contracts
    function setContracts(CoopItem _coopItem, CoopListing _coopListing, CoopVault _coopVault, H2OToken _h2oToken) external onlyAdmin {
        coopItem = _coopItem;
        coopListing = _coopListing;
        coopVault = _coopVault;
        h2oToken = _h2oToken;
    }

    // Change the coop tax
    function setCoopTax(uint256 _coopTax) external onlyAdmin {
        coopTax = _coopTax;
    }

    // Add a listing creator
    function addSeller(address _seller) external onlyAdmin {
        sellers[_seller] = true;
    }

    // Remove a listing creator
    function removeSeller(address _seller) external onlyAdmin {
        sellers[_seller] = false;
    }

    // *** Getters *** //

    // *** Listings *** //

    // Creates a new listing.
    function createListing(string memory name, string memory description, uint256 price, uint256 numberAvailable, uint256 expirationTime) 
        external 
        onlySeller
    {
        uint256 id = coopListing.mint(name, description, price, numberAvailable, expirationTime, msg.sender);
        emit ListingCreated(id, msg.sender, name, description, price, numberAvailable, expirationTime);
    }

    // *** Items *** //

    // Creates a new item.
    function createItem(uint256 listingId, uint256 number) external {
        require(coopListing.getListingNumberAvailable(listingId) >= number, "Not enough items available.");

        uint256 price = coopListing.getListingPrice(listingId);
        uint256 total = price.mul(number);
        uint256 coopFee = total.mul(coopTax);
        uint256 sellerFee = total - coopFee;

        h2oToken.transferFrom(msg.sender, address(coopVault), coopFee);
        h2oToken.transferFrom(msg.sender, coopListing.ownerOf(listingId), sellerFee);
        
        uint256 id = coopItem.mint(listingId, number, msg.sender);

        coopListing.reduceListingNumberAvailable(listingId, number);
        coopVault.addPatronage(msg.sender, total);
        
        emit ItemCreated(id, msg.sender, listingId, number);
    }

    // marks an item as sent
    function markItemSent(uint256 id) external {
        uint256 listingId = coopItem.getItemListing(id);
        require(coopListing.ownerOf(listingId) == msg.sender, "Only the seller can mark the item as sent.");
        coopItem.markItemSent(id);
    }

    // marks an item as received
    function markItemRecieved(uint256 id) external {
        require(coopItem.ownerOf(id) == msg.sender, "Only the buyer can mark the item as received.");
        coopItem.markItemRecieved(id);
    }

}