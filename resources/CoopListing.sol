// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../lib/FixedPoint.sol";
import "../abstract/ERC721Base.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

/// @title NFT contract for Coop Listing

contract CoopListing is ERC721Base
{
    // Use Fixed Point library for decimal ints.
    using UFixedPoint for uint256;
    using SFixedPoint for int256;

    /// @dev AccessControl role that gives access to createIceCube()
    //bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address public coopController;

    // Keeps track of the number of tokens minted so far.
    using Counters for Counters.Counter;
    Counters.Counter private _idCounter;

    struct Params {
        string name;
        string description;
        uint256 price;
        uint256 numberAvailable;
        uint256 numberSold;
        uint256 expirationTime;
    }

    mapping(uint256 => Params) public _params;

    /// @notice Initializer
    /// @param admins Addresses that will be granted the DEFAULT_ADMIN_ROLE.
    function initialize(address[] memory admins, address _coopController) 
        initializer public
    {
        __ERC721Base_init("Coop Listing", "LIST", admins);
        coopController = _coopController;
    }

    // *** Setters *** //

    // Changes the name of a listing.
    // function changeListingName(uint256 id, string memory name) external {
    //     require(_exists(id), "Invalid listing ID.");
    //     require(msg.sender == ownerOf(id), "Only the owner can change the name.");
    //     _params[id].name = name;
    // }

    // Changes the description of a listing.
    // function changeListingDescription(uint256 id, string memory description) external {
    //     require(_exists(id), "Invalid listing ID.");
    //     require(msg.sender == ownerOf(id), "Only the owner can change the description.");
    //     _params[id].description = description;
    // }

    // decreases the number of items available for a given listing.
    function reduceListingNumberAvailable(uint256 id, uint256 number) external {
        require(_exists(id), "Invalid listing ID.");
        require(msg.sender == coopController, "Only the controller can call the reduce function.");
        require(_params[id].numberAvailable >= number, "Cannot reduce the number available by that much.");
        _params[id].numberAvailable -= number;
    }

    // changes the number of items available by a given amount for a given listing.
    function changeListingNumberAvailable(uint256 id, uint256 number) external {
        require(_exists(id), "Invalid listing ID.");
        require(msg.sender == ownerOf(id), "Only the owner can call the change available number function.");
        _params[id].numberAvailable = number;
    }

    // Changes the price of a listing.
    function changeListingPrice(uint256 id, uint256 price) external {
        require(_exists(id), "Invalid listing ID.");
        require(msg.sender == ownerOf(id), "Only the owner can change the price.");
        _params[id].price = price;
    }

    // changes the expiration time of a listing.
    function changeListingExpirationTime(uint256 id, uint256 time) external {
        require(_exists(id), "Invalid listing ID.");
        require(msg.sender == ownerOf(id), "Only the owner can change the expiration time.");
        _params[id].expirationTime = time;
    }

    // increments the number of items sold for a given listing.
    function incrementNumberSold(uint256 id) external {
        require(_exists(id), "Invalid listing ID.");
        require(msg.sender == coopController, "Only the controller can increment the number sold.");
        _params[id].numberSold++;
    }

    // *** Getters *** //

    // gets the parameters of a listing
    function getListingParams(uint256 id) external view returns (Params memory) {
        require(_exists(id), "Invalid listing ID.");
        return _params[id];
    }

    // gets the name of a listing
    function getListingName(uint256 id) external view returns (string memory) {
        require(_exists(id), "Invalid listing ID.");
        return _params[id].name;
    }

    // gets the description of a listing
    function getListingDescription(uint256 id) external view returns (string memory) {
        require(_exists(id), "Invalid listing ID.");
        return _params[id].description;
    }

    // gets the price of a listing
    function getListingPrice(uint256 id) external view returns (uint256) {
        require(_exists(id), "Invalid listing ID.");
        return _params[id].price;
    }

    // gets the number available of a listing
    function getListingNumberAvailable(uint256 id) external view returns (uint256) {
        require(_exists(id), "Invalid listing ID.");
        return _params[id].numberAvailable;
    }

    // gets the number sold of a listing
    function getListingNumberSold(uint256 id) external view returns (uint256) {
        require(_exists(id), "Invalid listing ID.");
        return _params[id].numberSold;
    }

    // gets the expiration time of a listing
    function getListingExpirationTime(uint256 id) external view returns (uint256) {
        require(_exists(id), "Invalid listing ID.");
        return _params[id].expirationTime;
    }

    // *** Minting *** //

    /// @notice Mints a new ice cube NFT for recipient.
    /// @param name The name of the NFT.
    /// @param description The description of the NFT.
    /// @param price The price of the NFT.
    /// @param numberAvailable The number of items available.
    /// @param expirationTime The expiration time of the listing.
    /// @return id An identifier for the NFT.
    function mint(
        string memory name,
        string memory description,
        uint256 price,
        uint256 numberAvailable,
        uint256 expirationTime, 
        address recipient
    )
        external 
        returns (uint256)
    {
        require(msg.sender == coopController, "Only the controller can mint a listing.");
        // Mint starting with Id 1.
        _idCounter.increment();
        uint256 id = _idCounter.current();
        _safeMint(recipient, id);

        // Set the parameters for the new cube.
        _params[id] = Params({
            name: name,
            description: description,
            price: price,
            numberAvailable: numberAvailable,
            numberSold: 0,
            expirationTime: expirationTime
        });

        return id;
    }

}