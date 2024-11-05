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
    }

    struct Item {
        string name;
        uint256 price;
        uint256 rarity;
        address owner;
    }

    mapping(address => Player) public players;
    mapping(uint256 => Item) public items;
    mapping(address => uint256[]) public playerItems;
    uint256 public itemCount;
    uint256 public randomResult;
    bytes32 internal keyHash;
    uint256 internal fee;

    event PlayerRegistered(address indexed player, uint256 level, uint256 experience, uint256 balance);
    event ItemCreated(uint256 indexed itemId, string name, uint256 price, uint256 rarity);
    event ItemPurchased(uint256 indexed itemId, address indexed buyer, uint256 price);
    event ItemTransferred(uint256 indexed itemId, address indexed sender, address indexed recipient);

    modifier onlyRegisteredPlayer() {
        require(players[msg.sender].level != 0 || players[msg.sender].experience != 0 || players[msg.sender].balance != 0, "Caller is not a registered player");
        _;
    }

    modifier onlyItemOwner(uint256 itemId) {
        require(items[itemId].owner == msg.sender, "Caller does not own the item");
        _;
    }

    modifier onlyRegisteredRecipient(address recipient) {
        require(players[recipient].level != 0 || players[recipient].experience != 0 || players[recipient].balance != 0, "Recipient is not a registered player");
        _;
    }

    constructor(address _vrfCoordinator, address _link) VRFConsumerBase(_vrfCoordinator, _link) {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7b4b7f1a1b4b7f1a1b4; // Example keyHash, replace with actual
        fee = 0.1 * 10 ** 18; // Example fee, replace with actual
    }

function registerPlayer(uint256 level, uint256 experience, uint256 balance) public {
    // Check if the player is already registered
    Player storage existingPlayer = players[msg.sender];
    require(existingPlayer.level == 0 && existingPlayer.experience == 0 && existingPlayer.balance == 0, "Player is already registered");

    // Create a new Player struct and set its properties
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

    // Increment the itemCount to generate a new unique item ID
    itemCount = itemCount + 1;
    uint256 newItemId = itemCount;

    // Request a random number using the Chainlink VRF service to determine the item's rarity
    bytes32 requestId = requestRandomness(keyHash, fee);

    // Create a new Item struct with the provided name, price, and the generated rarity
    Item storage newItem = items[newItemId];
    newItem.name = name;
    newItem.price = price;
    newItem.rarity = randomResult; // Assuming randomResult is set by fulfillRandomness

    // Store the new item in the items mapping using the new item ID
    items[newItemId] = newItem;

    // Emit the ItemCreated event with the item ID, name, price, and rarity
    emit ItemCreated(newItemId, name, price, randomResult);
}


function purchaseItem(uint256 itemId) public onlyRegisteredPlayer {
    // Check if the item exists
    Item storage item = items[itemId];
    require(bytes(item.name).length != 0, "Item does not exist");

    // Verify that the item is not already owned by the caller
    uint256[] storage ownedItems = playerItems[msg.sender];
    for (uint256 i = 0; i < ownedItems.length; i = i + 1) {
        require(ownedItems[i] != itemId, "Item already owned by the caller");
    }

    // Ensure the caller has sufficient balance to purchase the item
    Player storage player = players[msg.sender];
    require(player.balance >= item.price, "Insufficient balance to purchase item");

    // Deduct the item price from the caller's balance
    player.balance = SafeMathChainlink.sub(player.balance, item.price);

    // Assign ownership of the item to the caller
    playerItems[msg.sender].push(itemId);

    // Emit the ItemPurchased event
    emit ItemPurchased(itemId, msg.sender, item.price);
}


function transferItem(uint256 itemId, address recipient) public onlyRegisteredPlayer onlyItemOwner(itemId) onlyRegisteredRecipient(recipient) {
    // Remove the item from the caller's list of owned items
    uint256[] storage senderItems = playerItems[msg.sender];
    for (uint256 i = 0; i < senderItems.length; i = i + 1) {
        if (senderItems[i] == itemId) {
            senderItems[i] = senderItems[senderItems.length - 1];
            senderItems.pop();
            break;
        }
    }

    // Add the item to the recipient's list of owned items
    uint256[] storage recipientItems = playerItems[recipient];
    recipientItems.push(itemId);

    // Update the owner of the item in the items mapping
    Item storage item = items[itemId];
    item.owner = recipient;

    // Emit the ItemTransferred event
    emit ItemTransferred(itemId, msg.sender, recipient);
}


function getPlayerDetails(address player) public view returns (uint256 level, uint256 experience, uint256 balance) {
    Player storage playerDetails = players[player];
    require(playerDetails.level != 0 || playerDetails.experience != 0 || playerDetails.balance != 0, "Player not registered");

    uint256 playerLevel = playerDetails.level;
    uint256 playerExperience = playerDetails.experience;
    uint256 playerBalance = playerDetails.balance;

    return (playerLevel, playerExperience, playerBalance);
}


function getItemDetails(uint256 itemId) public view returns (string memory name, uint256 price, uint256 rarity) {
    Item storage item = items[itemId];

    // Ensure the item exists
    require(bytes(item.name).length != 0, "Item does not exist");

    name = item.name;
    price = item.price;
    rarity = item.rarity;

    return (name, price, rarity);
}


function getPlayerItems(address player) public view returns (uint256[] memory) {
    return playerItems[player];
}


function getPlayerBalance() public view onlyRegisteredPlayer returns (uint256) {
    Player storage player = players[msg.sender];
    uint256 balance = player.balance;
    return balance;
}


function addFunds(uint256 amount) public onlyRegisteredPlayer {
    Player storage player = players[msg.sender];
    player.balance = player.balance + amount;
}


function requestRandomNumber() public onlyRegisteredPlayer returns (bytes32 requestId) {
    uint256 linkBalance = LINK.balanceOf(address(this));
    require(linkBalance >= fee, "Not enough LINK to pay fee");

    requestId = requestRandomness(keyHash, fee);
}


function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    randomResult = randomness;
}


}