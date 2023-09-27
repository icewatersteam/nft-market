// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../lib/FixedPoint.sol";
import "../abstract/ERC721Base.sol";

import "./CoopListing.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

/// @title NFT contract for a Coop Item

contract CoopItem is ERC721Base
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
        uint256 listingId;
        uint256 number;
        bool sent;
        bool received;
    }

    mapping(uint256 => Params) private _params;

    /// @notice Initializer
    /// @param admins Addresses that will be granted the DEFAULT_ADMIN_ROLE.
    function initialize(address[] memory admins, address _coopController) 
        initializer public
    {
        __ERC721Base_init("Coop Listing", "LIST", admins);
        coopController = _coopController;
    }

    // *** Setters *** //

    // Updates whether an item has been fulfilled.
    function markItemSent(uint id) external {
        require(msg.sender == coopController, "Only the coop controller can mark items as sent.");
        _params[id].sent = true;
    }

    // Updates whether an item has been received.
    function markItemRecieved(uint id) external {
        require(msg.sender == coopController, "Only the coop controller can mark items as received.");
        _params[id].received = true;
    }

    // *** Getters *** //

    // Gets the listing ID of an item.
    function getItemListing(uint256 id) external view returns (uint256 listingId) {
        require(_exists(id), "Invalid item ID.");
        return _params[id].listingId;
    }

    // Gets the number of an item.
    function getItemNumber(uint256 id) external view returns (uint256) {
        require(_exists(id), "Invalid item ID.");
        return _params[id].number;
    }

    // *** Minting *** //

    // mints a new coop item
    function mint(
        uint256 listingId,
        uint256 number,
        address recipient
    ) 
        external returns (uint256)
    {
        require(msg.sender == coopController, "Only the coop controller can mint items.");
        _idCounter.increment();
        uint256 id = _idCounter.current();
        _mint(recipient, id);

        _params[id] = Params(
            listingId,
            number, 
            false, 
            false
        );

        return id;
    }
}