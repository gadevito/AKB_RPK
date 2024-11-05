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
    address public vrfCoordinator;
    address public linkToken;
    bytes32 public keyHash;
    uint256 public fee;
    mapping(bytes32 => uint256) public requestIdToItemId;

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

    constructor(address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee) 
        VRFConsumerBase(_vrfCoordinator, _linkToken) 
    {
        vrfCoordinator = _vrfCoordinator;
        linkToken = _linkToken;
        keyHash = _keyHash;
        fee = _fee;
    }

    function registerPlayer(uint256 level, uint256 experience, uint256 balance) public {
        // Check if the player is already registered
        Player storage existingPlayer = players[msg.sender];
        require(existingPlayer.level == 0 && existingPlayer.experience == 0 && existingPlayer.balance == 0, "Player is already registered");

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
        LinkTokenInterface link = LinkTokenInterface(linkToken);
        require(link.balanceOf(address(this)) >= fee, "Not enough LINK tokens");

        // Increment the itemCount to generate a new unique item ID
        itemCount = itemCount + 1;
        uint256 newItemId = itemCount;

        // Request a random number using Chainlink VRF to determine the item's rarity
        bytes32 requestId = requestRandomness(keyHash, fee);

        // Store the new item in the items mapping with the generated item ID, name, and price
        Item storage newItem = items[newItemId];
        newItem.name = name;
        newItem.price = price;

        // Emit the ItemCreated event with the item ID, name, price, and a placeholder rarity (to be updated later)
        emit ItemCreated(newItemId, name, price, 0);

        // Store the requestId and newItemId mapping to update the rarity once randomness is fulfilled
        requestIdToItemId[requestId] = newItemId;
    }

    function purchaseItem(uint256 itemId) public onlyRegisteredPlayer {
        // Check if the item exists and is not already owned
        Item storage item = items[itemId];
        require(bytes(item.name).length != 0, "Item does not exist");
        require(item.owner == address(0), "Item is already owned");

        // Verify that the caller has sufficient balance to purchase the item
        Player storage player = players[msg.sender];
        require(player.balance >= item.price, "Insufficient balance to purchase the item");

        // Deduct the item price from the caller's balance
        player.balance = SafeMathChainlink.sub(player.balance, item.price);

        // Assign ownership of the item to the caller
        item.owner = msg.sender;

        // Emit the ItemPurchased event
        emit ItemPurchased(itemId, msg.sender, item.price);
    }

    function transferItem(uint256 itemId, address recipient) public onlyRegisteredPlayer onlyItemOwner(itemId) onlyRegisteredRecipient(recipient) {
        // Ensure the caller is a registered player
        require(players[msg.sender].level != 0, "Caller is not a registered player");

        // Ensure the caller is the owner of the item
        Item storage item = items[itemId];
        require(item.owner == msg.sender, "Caller is not the owner of the item");

        // Ensure the recipient is a registered player
        require(players[recipient].level != 0, "Recipient is not a registered player");

        // Update the ownership of the item
        item.owner = recipient;

        // Emit the ItemTransferred event
        emit ItemTransferred(itemId, msg.sender, recipient);
    }

    function getPlayerDetails(address player) public view returns (uint256 level, uint256 experience, uint256 balance) {
        Player storage playerDetails = players[player];
        if (playerDetails.level == 0 && playerDetails.experience == 0 && playerDetails.balance == 0) {
            return (0, 0, 0);
        }
        return (playerDetails.level, playerDetails.experience, playerDetails.balance);
    }

    function getItemDetails(uint256 itemId) public view returns (string memory name, uint256 price, uint256 rarity) {
        Item storage item = items[itemId];

        require(bytes(item.name).length != 0, "Item does not exist");

        name = item.name;
        price = item.price;
        rarity = item.rarity;

        return (name, price, rarity);
    }

    function getPlayerItems(address player) public view returns (uint256[] memory) {
        // Ensure the player is registered
        Player storage p = players[player];
        require(p.level != 0 || p.experience != 0 || p.balance != 0, "Player not registered");

        // Retrieve the list of item IDs owned by the player
        uint256 ownedItemCount = 0;
        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].owner == player) {
                ownedItemCount++;
            }
        }

        uint256[] memory ownedItems = new uint256[](ownedItemCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= itemCount; i++) {
            if (items[i].owner == player) {
                ownedItems[index] = i;
                index++;
            }
        }

        // Return the list of item IDs
        return ownedItems;
    }

    function getPlayerBalance() public view onlyRegisteredPlayer returns (uint256) {
        Player storage player = players[msg.sender];
        return player.balance;
    }

    function addFunds(uint256 amount) public onlyRegisteredPlayer {
        require(amount > 0, "Amount must be greater than zero");

        Player storage player = players[msg.sender];
        uint256 currentBalance = player.balance;
        uint256 newBalance = SafeMathChainlink.add(currentBalance, amount);

        player.balance = newBalance;
    }

    function requestRandomNumber() public onlyRegisteredPlayer returns (bytes32 requestId) {
        LinkTokenInterface link = LinkTokenInterface(linkToken);
        uint256 linkBalance = link.balanceOf(address(this));

        require(linkBalance >= fee, "Not enough LINK to pay fee");

        requestId = requestRandomness(keyHash, fee);
        return requestId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 itemId = requestIdToItemId[requestId];
        Item storage item = items[itemId];
        item.rarity = randomness;

        // Emit the ItemCreated event again with the updated rarity
        emit ItemCreated(itemId, item.name, item.price, item.rarity);
    }
}