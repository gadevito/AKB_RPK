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
    mapping(uint256 => Item) public items;
    mapping(address => uint256[]) public playerItems;
    mapping(bytes32 => address) private requestToSender;
    mapping(bytes32 => string) private requestToItemName;
    mapping(bytes32 => uint256) private requestToItemPrice;
    uint256 public itemCount;
    uint256 public randomResult;

    bytes32 internal keyHash;
    uint256 internal fee;

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
        bytes32 requestId = requestRandomNumber();
        requestToSender[requestId] = msg.sender;
        requestToItemName[requestId] = name;
        requestToItemPrice[requestId] = price;
    }

    function purchaseItem(uint256 itemId) external {
        require(players[msg.sender].registered, "Only registered players can purchase items");
        require(items[itemId].owner == address(0), "Item already owned");
        require(players[msg.sender].balance >= items[itemId].price, "Insufficient balance");

        players[msg.sender].balance = players[msg.sender].balance.sub(items[itemId].price);
        items[itemId].owner = msg.sender;
        playerItems[msg.sender].push(itemId);

        emit ItemPurchased(itemId, msg.sender, items[itemId].price);
    }

    function transferItem(uint256 itemId, address recipient) external {
        require(items[itemId].owner == msg.sender, "Only the owner can transfer the item");
        require(players[recipient].registered, "Recipient must be a registered player");

        items[itemId].owner = recipient;
        playerItems[recipient].push(itemId);

        uint256[] storage senderItems = playerItems[msg.sender];
        for (uint256 i = 0; i < senderItems.length; i++) {
            if (senderItems[i] == itemId) {
                senderItems[i] = senderItems[senderItems.length - 1];
                senderItems.pop();
                break;
            }
        }

        emit ItemTransferred(itemId, msg.sender, recipient);
    }

    function getPlayerDetails(address player) external view returns (uint256 level, uint256 experience, uint256 balance) {
        Player memory p = players[player];
        return (p.level, p.experience, p.balance);
    }

    function getItemDetails(uint256 itemId) external view returns (string memory name, uint256 price, uint256 rarity, address owner) {
        Item memory item = items[itemId];
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
        address itemCreator = requestToSender[requestId];
        string memory itemName = requestToItemName[requestId];
        uint256 itemPrice = requestToItemPrice[requestId];
        uint256 rarity = randomness % 100; // Example logic to map randomness to a rarity level

        items[itemCount] = Item(itemName, itemPrice, rarity, address(0));
        emit ItemCreated(itemCount, itemName, itemPrice, rarity);
        itemCount = itemCount.add(1);
    }
}