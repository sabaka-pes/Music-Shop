// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165.sol";

contract MusicShop is ERC165{
    enum OrderStatus {
        Paid,
        Delivered
    }

    struct Album {
        uint256 index;
        bytes32 uid;
        string title;
        uint256 price;
        uint256 quantity;
    }

    struct Order {
        uint256 orderId;
        bytes32 albumUid;
        address customer;
        uint256 orderedAt;
        OrderStatus status;
    }

    Album[] public albums;
    Order[] public orders;

    uint256 public currentIndex;
    uint256 public currentOrderId;

    address public owner;

    event AlbumBought(bytes32 indexed uid, address indexed customer, uint256 indexed timestamp);
    event OrderDelivered(bytes32 indexed albumUid, address indexed customer);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner.");
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function addAlbum(bytes32 _uid, string calldata _title, uint256 _price, uint256 _quantity) external onlyOwner {
        albums.push(
            Album({
                index: currentIndex,
                uid: _uid,
                title: _title,
                price: _price,
                quantity: _quantity
            })
        );
        currentIndex++;
    }

    function buy(uint256 _index) external payable {
        Album storage albumToBuy = albums[_index];

        require(albumToBuy.quantity > 0, "Out of stock.");
        require(msg.value == albumToBuy.price, "Invalid price.");

        albumToBuy.quantity--;

        orders.push(
            Order({
                orderId: currentOrderId,
                albumUid: albumToBuy.uid,
                customer: msg.sender,
                orderedAt: block.timestamp,
                status: OrderStatus.Paid
            })
        );
        currentOrderId++;

        emit AlbumBought(albumToBuy.uid, msg.sender, block.timestamp);
    }

    function delivered(uint256 _index) external onlyOwner {
        Order storage currentOrder = orders[_index];

        require(currentOrder.status != OrderStatus.Delivered, "Invalid status.");

        currentOrder.status = OrderStatus.Delivered;

        emit OrderDelivered(currentOrder.albumUid, currentOrder.customer);
    }

    receive() external payable {
        revert("Please use the buy function to purchase albums.");
    }

    function allAlbums() external view returns(Album[] memory) {
        uint totalAlbums = albums.length;
        Album[] memory albumLists = new Album[](totalAlbums);

        for (uint256 i = 0; i < totalAlbums; i++) {
            albumLists[i] = albums[i];
        }

        return albumLists;
    }

    fallback() external {}
}