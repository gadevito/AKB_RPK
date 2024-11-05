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
        require(players[msg.sender].balance > 0, "Caller is not a registered player");
        _;
    }

    modifier onlyItemOwner(uint256 itemId) {
        require(items[itemId].owner == msg.sender, "Caller is not the owner of the item");
        _;
    }

    modifier onlyRegisteredRecipient(address recipient) {
        require(players[recipient].balance > 0, "Recipient is not a registered player");
        _;
    }

    constructor(address _vrfCoordinator, address _link) VRFConsumerBase(_vrfCoordinator, _link) public {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7b4b1e3b3e3d7e8e4d4; // Example keyHash
        fee = 0.1 * 10 ** 18; // Example fee
    }

    function registerPlayer(uint256 _level, uint256 _experience, uint256 _balance) public {
        Player storage player = players[msg.sender];
        require(player.balance == 0, "Player is already registered");

        player.level = _level;
        player.experience = _experience;
        player.balance = _balance;

        emit PlayerRegistered(msg.sender, _level, _experience, _balance);
    }

    function createItem(string memory name, uint256 price) public onlyRegisteredPlayer {
        // Increment the itemCount to generate a new unique item ID
        itemCount = itemCount + 1;
        uint256 newItemId = itemCount;

        // Ensure the contract has enough LINK tokens to request randomness
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");

        // Request a random number to determine the item's rarity
        bytes32 requestId = requestRandomness(keyHash, fee);

        // Store the item details in the items mapping
        Item storage newItem = items[newItemId];
        newItem.name = name;
        newItem.price = price;
        newItem.owner = msg.sender;

        // Emit the ItemCreated event
        emit ItemCreated(newItemId, name, price, randomResult);
    }

    function purchaseItem(uint256 itemId) public onlyRegisteredPlayer {
        // Check if the item is already owned by someone
        Item storage item = items[itemId];
        address itemOwner = item.owner;
        require(itemOwner == address(0), "Item is already owned");

        // Verify that the caller has sufficient balance to purchase the item
        Player storage player = players[msg.sender];
        uint256 playerBalance = player.balance;
        uint256 itemPrice = item.price;
        require(playerBalance >= itemPrice, "Insufficient balance to purchase the item");

        // Deduct the item price from the caller's balance
        player.balance = playerBalance - itemPrice;

        // Assign ownership of the item to the caller
        item.owner = msg.sender;

        // Emit the ItemPurchased event
        emit ItemPurchased(itemId, msg.sender, itemPrice);
    }

    function transferItem(uint256 itemId, address recipient) public onlyItemOwner(itemId) onlyRegisteredRecipient(recipient) {
        // Update the ownership of the item
        Item storage item = items[itemId];
        item.owner = recipient;

        // Emit the ItemTransferred event
        emit ItemTransferred(itemId, msg.sender, recipient);
    }

    function getPlayerDetails(address player) public view returns (uint256 level, uint256 experience, uint256 balance) {
        Player storage p = players[player];
        require(p.balance > 0, "Player not registered");

        return (p.level, p.experience, p.balance);
    }

    function getItemDetails(uint256 itemId) public view returns (string memory name, uint256 price, uint256 rarity, address owner) {
        Item storage item = items[itemId];
        address itemOwner = item.owner;

        require(itemOwner != address(0), "Item does not exist");

        name = item.name;
        price = item.price;
        rarity = item.rarity;
        owner = itemOwner;
    }

    function getPlayerItems(address player) public view returns (uint256[] memory) {
        // Check if the player is registered
        Player storage playerData = players[player];
        if (playerData.balance == 0) {
            revert("Player not registered");
        }

        // Create a temporary array to store item IDs
        uint256[] memory ownedItems = new uint256[](itemCount);
        uint256 count = 0;

        // Iterate through all items to find those owned by the player
        for (uint256 i = 1; i <= itemCount; i = i + 1) {
            Item storage item = items[i];
            if (item.owner == player) {
                ownedItems[count] = i;
                count = count + 1;
            }
        }

        // Create a new array with the exact size of owned items
        uint256[] memory result = new uint256[](count);
        for (uint256 j = 0; j < count; j = j + 1) {
            result[j] = ownedItems[j];
        }

        return result;
    }

    function getPlayerBalance() public view onlyRegisteredPlayer returns (uint256) {
        Player storage player = players[msg.sender];
        uint256 balance = player.balance;
        return balance;
    }

    function addFunds(uint256 amount) public onlyRegisteredPlayer {
        require(amount > 0, "Amount must be greater than zero");

        Player storage player = players[msg.sender];
        player.balance = player.balance + amount;
    }

    function requestRandomNumber() public onlyRegisteredPlayer returns (bytes32 requestId) {
        uint256 linkBalance = LINK.balanceOf(address(this));
        require(linkBalance >= fee, "Not enough LINK to pay fee");

        bytes32 reqId = requestRandomness(keyHash, fee);
        return reqId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }
}