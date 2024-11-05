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
        require(players[msg.sender].level != 0, "Caller is not a registered player");
        _;
    }

    modifier onlyItemOwner(uint256 itemId) {
        require(items[itemId].owner == msg.sender, "Caller is not the owner of the item");
        _;
    }

    modifier onlyRegisteredRecipient(address recipient) {
        require(players[recipient].level != 0, "Recipient is not a registered player");
        _;
    }

    constructor(address _vrfCoordinator, address _link) VRFConsumerBase(_vrfCoordinator, _link) public {
        // Constructor logic here
    }

    function registerPlayer(uint256 level, uint256 experience, uint256 balance) public {
        // Check if the player is already registered
        Player storage player = players[msg.sender];
        require(player.level == 0, "Player is already registered");

        // Initialize the new player
        player.level = level;
        player.experience = experience;
        player.balance = balance;

        // Emit the PlayerRegistered event
        emit PlayerRegistered(msg.sender, level, experience, balance);
    }

    function createItem(string memory name, uint256 price) public onlyRegisteredPlayer {
        // Increment the itemCount to generate a new item ID
        itemCount = itemCount + 1;
        uint256 newItemId = itemCount;

        // Ensure the contract has enough LINK tokens to request randomness
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");

        // Request a random number to determine the item's rarity
        bytes32 requestId = requestRandomness(keyHash, fee);

        // Create a new item and store it in the items mapping
        Item storage newItem = items[newItemId];
        newItem.name = name;
        newItem.price = price;
        newItem.rarity = randomResult; // This will be set once fulfillRandomness is called

        // Emit the ItemCreated event
        emit ItemCreated(newItemId, name, price, randomResult);
    }

    function purchaseItem(uint256 itemId) public onlyRegisteredPlayer {
        // Check if the item exists and is not already owned
        Item storage item = items[itemId];
        require(bytes(item.name).length != 0, "Item does not exist");
        require(item.owner == address(0), "Item already owned");

        // Verify the caller has sufficient balance to purchase the item
        Player storage player = players[msg.sender];
        require(player.balance >= item.price, "Insufficient balance");

        // Deduct the item price from the caller's balance
        player.balance = player.balance - item.price;

        // Assign ownership of the item to the caller
        item.owner = msg.sender;

        // Add the item to the player's owned items
        player.ownedItems.push(itemId);

        // Emit the ItemPurchased event
        emit ItemPurchased(itemId, msg.sender, item.price);
    }

    function transferItem(uint256 itemId, address recipient) public onlyItemOwner(itemId) onlyRegisteredRecipient(recipient) {
        // Ensure the caller is the owner of the item
        Item storage item = items[itemId];
        address sender = msg.sender;

        // Update the ownership of the item
        item.owner = recipient;

        // Emit the ItemTransferred event
        emit ItemTransferred(itemId, sender, recipient);
    }

    function getPlayerDetails(address player) public view returns (uint256 level, uint256 experience, uint256 balance) {
        Player storage playerDetails = players[player];
        uint256 playerLevel = playerDetails.level;

        require(playerLevel != 0, "Player not registered");

        uint256 playerExperience = playerDetails.experience;
        uint256 playerBalance = playerDetails.balance;

        return (playerLevel, playerExperience, playerBalance);
    }

    function getItemDetails(uint256 itemId) public view returns (string memory name, uint256 price, uint256 rarity) {
        Item storage item = items[itemId];

        require(bytes(item.name).length > 0, "Item does not exist");

        return (item.name, item.price, item.rarity);
    }

    function getPlayerItems(address player) public view returns (uint256[] memory) {
        // Check if the player is registered by verifying their level is not zero
        Player storage playerData = players[player];
        uint256 playerLevel = playerData.level;
        require(playerLevel != 0, "Player not registered");

        // Retrieve the list of item IDs owned by the player
        uint256[] memory ownedItems = playerData.ownedItems;

        // Return the list of item IDs
        return ownedItems;
    }

    function getPlayerBalance() public view onlyRegisteredPlayer returns (uint256) {
        Player storage player = players[msg.sender];
        uint256 balance = player.balance;
        return balance;
    }

    function addFunds(uint256 amount) public onlyRegisteredPlayer {
        // Retrieve the player's current balance
        Player storage player = players[msg.sender];
        uint256 currentBalance = player.balance;

        // Safely add the specified amount to the player's balance
        uint256 newBalance = currentBalance + amount;

        // Update the player's balance in the players mapping
        player.balance = newBalance;
    }

    function requestRandomNumber() public onlyRegisteredPlayer returns (bytes32 requestId) {
        uint256 linkBalance = LINK.balanceOf(address(this));
        require(linkBalance >= fee, "Not enough LINK to pay fee");

        bytes32 reqId = requestRandomness(keyHash, fee);
        return reqId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;

        // Additional logic depending on the random number can be added here
    }
}