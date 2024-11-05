pragma solidity >=0.4.22 <0.9.0;

import './hardhat/interfaces/LinkTokenInterface.sol';
import './hardhat/vendor/SafeMathChainlink.sol';
import './hardhat/VRFRequestIDBase.sol';
import './hardhat/VRFConsumerBase.sol';

contract GameContract is VRFConsumerBase {
    using SafeMathChainlink for uint256;

    struct Player {
        uint256 level;
        uint256 experience;
        uint256 balance;
        uint256[] ownedItems;
    }

    struct Item {
        string name;
        uint256 price;
        uint256 rarity;
        address owner;
    }

    mapping(address => Player) public players;
    mapping(uint256 => Item) public items;
    uint256 public itemCount;
    uint256 public randomResult;
    bytes32 public keyHash;
    uint256 public fee;

    event PlayerRegistered(address indexed player, uint256 level, uint256 experience, uint256 balance);
    event ItemCreated(uint256 indexed itemId, string name, uint256 price, uint256 rarity);
    event ItemPurchased(uint256 indexed itemId, address indexed buyer, uint256 price);
    event ItemTransferred(uint256 indexed itemId, address indexed sender, address indexed recipient);

    modifier onlyRegisteredPlayer() {
        require(players[msg.sender].level > 0, "Caller is not a registered player");
        _;
    }

    modifier onlyItemOwner(uint256 itemId) {
        require(items[itemId].owner == msg.sender, "Caller is not the owner of the item");
        _;
    }

    modifier onlyRegisteredRecipient(address recipient) {
        require(players[recipient].level > 0, "Recipient is not a registered player");
        _;
    }

    constructor(address _vrfCoordinator, address _link) VRFConsumerBase(_vrfCoordinator, _link) {
        // Constructor logic here
    }

    function registerPlayer(uint256 level, uint256 experience, uint256 balance) public {
        // Check if the player is already registered
        Player storage existingPlayer = players[msg.sender];
        require(existingPlayer.level == 0, "Player is already registered");

        // Create a new Player struct
        Player storage newPlayer = players[msg.sender];
        newPlayer.level = level;
        newPlayer.experience = experience;
        newPlayer.balance = balance;

        // Emit the PlayerRegistered event
        emit PlayerRegistered(msg.sender, level, experience, balance);
    }

    function createItem(string memory name, uint256 price) public onlyRegisteredPlayer {
        // Ensure the contract has enough LINK tokens to request randomness
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");

        // Increment the itemCount to generate a unique item ID
        itemCount = itemCount + 1;
        uint256 newItemId = itemCount;

        // Request a random number using Chainlink VRF to determine the item's rarity
        bytes32 requestId = requestRandomness(keyHash, fee);

        // Create a new Item struct with the provided name and price
        Item storage newItem = items[newItemId];
        newItem.name = name;
        newItem.price = price;
        newItem.rarity = randomResult; // This will be set once the randomness is fulfilled

        // Emit the ItemCreated event with the item ID, name, price, and rarity
        emit ItemCreated(newItemId, name, price, randomResult);
    }

    function purchaseItem(uint256 itemId) public onlyRegisteredPlayer {
        // Retrieve the item from the items mapping
        Item storage item = items[itemId];

        // Check if the item is already owned by another player
        require(item.owner == address(0), "Item is already owned");

        // Retrieve the player from the players mapping
        Player storage player = players[msg.sender];

        // Verify that the caller has sufficient balance to purchase the item
        require(player.balance >= item.price, "Insufficient balance to purchase item");

        // Deduct the item price from the caller's balance
        player.balance = player.balance - item.price;

        // Assign ownership of the item to the caller
        item.owner = msg.sender;

        // Add the item to the player's owned items
        player.ownedItems.push(itemId);

        // Emit the ItemPurchased event
        emit ItemPurchased(itemId, msg.sender, item.price);
    }

    function transferItem(uint256 itemId, address recipient) public onlyRegisteredPlayer onlyItemOwner(itemId) onlyRegisteredRecipient(recipient) {
        // Check if the caller is a registered player
        Player storage senderPlayer = players[msg.sender];
        require(senderPlayer.level > 0, "Caller is not a registered player");

        // Check if the caller is the owner of the item
        Item storage item = items[itemId];
        require(item.owner == msg.sender, "Caller is not the owner of the item");

        // Check if the recipient is a registered player
        Player storage recipientPlayer = players[recipient];
        require(recipientPlayer.level > 0, "Recipient is not a registered player");

        // Update the ownership of the item to the recipient
        item.owner = recipient;

        // Emit the ItemTransferred event
        emit ItemTransferred(itemId, msg.sender, recipient);
    }

    function getPlayerDetails(address playerAddress) public view returns (uint256 level, uint256 experience, uint256 balance) {
        Player storage player = players[playerAddress];
        require(player.level > 0, "Player not registered");

        return (player.level, player.experience, player.balance);
    }

    function getItemDetails(uint256 itemId) public view returns (string memory name, uint256 price, uint256 rarity, address owner) {
        Item storage item = items[itemId];

        require(bytes(item.name).length > 0, "Item does not exist");

        name = item.name;
        price = item.price;
        rarity = item.rarity;
        owner = item.owner;

        return (name, price, rarity, owner);
    }

    function getPlayerItems(address playerAddress) public view returns (uint256[] memory) {
        // Check if the player is registered by verifying their level is greater than 0
        Player storage player = players[playerAddress];
        uint256 playerLevel = player.level;
        require(playerLevel > 0, "Player not registered");

        // Retrieve the list of item IDs owned by the player
        uint256[] storage ownedItems = player.ownedItems;

        // Return the list of item IDs
        return ownedItems;
    }

    function getPlayerBalance() public view onlyRegisteredPlayer returns (uint256) {
        Player storage player = players[msg.sender];
        return player.balance;
    }

    function addFunds(uint256 amount) public onlyRegisteredPlayer {
        require(amount > 0, "Amount must be positive");

        Player storage player = players[msg.sender];
        player.balance += amount;
    }

    function requestRandomNumber() public onlyRegisteredPlayer returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");

        requestId = requestRandomness(keyHash, fee);
        return requestId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }
}