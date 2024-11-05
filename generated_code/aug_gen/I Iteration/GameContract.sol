// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./hardhat/interfaces/LinkTokenInterface.sol";
import "./hardhat/vendor/SafeMathChainlink.sol";
import "./hardhat/VRFRequestIDBase.sol";
import "./hardhat/VRFConsumerBase.sol";

contract GameContract is VRFConsumerBase {
    using SafeMathChainlink for uint256;

    struct Player {
        uint256 level;
        uint256 experience;
        uint256 balance;
        bool registered;
    }

    struct Item {
        string name;
        uint256 price;
        uint256 rarity;
        address owner;
    }

    mapping(address => Player) public players;
    Item[] public items;
    mapping(address => uint256[]) public playerItems;
    mapping(bytes32 => uint256) private requestIdToItemId;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;

    event PlayerRegistered(address indexed player, uint256 level, uint256 experience, uint256 balance);
    event ItemCreated(uint256 indexed itemId, string name, uint256 price, uint256 rarity);
    event ItemPurchased(uint256 indexed itemId, address indexed buyer, uint256 price);
    event ItemTransferred(uint256 indexed itemId, address indexed sender, address indexed recipient);

    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint256 _fee) 
        VRFConsumerBase(_vrfCoordinator, _link) 
    {
        keyHash = _keyHash;
        fee = _fee;
    }

    function registerPlayer(uint256 level, uint256 experience, uint256 balance) external {
        require(!players[msg.sender].registered, "Player already registered");
        players[msg.sender] = Player(level, experience, balance, true);
        emit PlayerRegistered(msg.sender, level, experience, balance);
    }

    function createItem(string memory name, uint256 price) external {
        require(players[msg.sender].registered, "Only registered players can create items");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");
        uint256 itemId = items.length;
        bytes32 requestId = requestRandomNumber();
        requestIdToItemId[requestId] = itemId;
        items.push(Item(name, price, 0, msg.sender));
    }

    function purchaseItem(uint256 itemId) external {
        require(itemId < items.length, "Item does not exist");
        Item storage item = items[itemId];
        require(item.owner == address(0), "Item already owned");
        require(players[msg.sender].balance >= item.price, "Insufficient balance");
        players[msg.sender].balance = players[msg.sender].balance.sub(item.price);
        item.owner = msg.sender;
        playerItems[msg.sender].push(itemId);
        emit ItemPurchased(itemId, msg.sender, item.price);
    }

    function transferItem(uint256 itemId, address recipient) external {
        require(itemId < items.length, "Item does not exist");
        Item storage item = items[itemId];
        require(item.owner == msg.sender, "Only the owner can transfer the item");
        require(players[recipient].registered, "Recipient must be a registered player");
        item.owner = recipient;
        playerItems[recipient].push(itemId);
        emit ItemTransferred(itemId, msg.sender, recipient);
    }

    function getPlayerDetails(address player) external view returns (uint256 level, uint256 experience, uint256 balance) {
        Player storage p = players[player];
        return (p.level, p.experience, p.balance);
    }

    function getItemDetails(uint256 itemId) external view returns (string memory name, uint256 price, uint256 rarity, address owner) {
        Item storage item = items[itemId];
        return (item.name, item.price, item.rarity, item.owner);
    }

    function getPlayerItems(address player) external view returns (uint256[] memory) {
        return playerItems[player];
    }

    function getPlayerBalance() external view returns (uint256) {
        return players[msg.sender].balance;
    }

    function addFunds(uint256 amount) external {
        players[msg.sender].balance = players[msg.sender].balance.add(amount);
    }

    function requestRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 itemId = requestIdToItemId[requestId];
        require(itemId < items.length, "Item does not exist");
        items[itemId].rarity = randomness;
        emit ItemCreated(itemId, items[itemId].name, items[itemId].price, randomness);
    }
}