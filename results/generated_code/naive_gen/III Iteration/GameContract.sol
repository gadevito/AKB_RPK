// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./hardhat/interfaces/LinkTokenInterface.sol";
import "./hardhat/vendor/SafeMathChainlink.sol";
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
    uint256 public itemCount;
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

    function registerPlayer(uint256 level, uint256 experience, uint256 balance) public {
        require(!players[msg.sender].registered, "Player already registered");
        players[msg.sender] = Player(level, experience, balance, true);
        emit PlayerRegistered(msg.sender, level, experience, balance);
    }

    function createItem(string memory name, uint256 price) public {
        require(players[msg.sender].registered, "Only registered players can create items");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");
        requestRandomNumber();
        uint256 rarity = randomResult;
        items[itemCount] = Item(name, price, rarity, address(0));
        emit ItemCreated(itemCount, name, price, rarity);
        itemCount = itemCount.add(1);
    }

    function purchaseItem(uint256 itemId) public {
        require(players[msg.sender].registered, "Only registered players can purchase items");
        require(items[itemId].owner == address(0), "Item already owned");
        require(players[msg.sender].balance >= items[itemId].price, "Insufficient balance");
        players[msg.sender].balance = players[msg.sender].balance.sub(items[itemId].price);
        items[itemId].owner = msg.sender;
        playerItems[msg.sender].push(itemId);
        emit ItemPurchased(itemId, msg.sender, items[itemId].price);
    }

    function transferItem(uint256 itemId, address recipient) public {
        require(items[itemId].owner == msg.sender, "Only the owner can transfer the item");
        require(players[recipient].registered, "Recipient must be a registered player");
        items[itemId].owner = recipient;
        playerItems[recipient].push(itemId);
        emit ItemTransferred(itemId, msg.sender, recipient);
    }

    function getPlayerDetails(address player) public view returns (uint256, uint256, uint256) {
        require(players[player].registered, "Player not registered");
        Player memory p = players[player];
        return (p.level, p.experience, p.balance);
    }

    function getItemDetails(uint256 itemId) public view returns (string memory, uint256, uint256, address) {
        Item memory i = items[itemId];
        return (i.name, i.price, i.rarity, i.owner);
    }

    function getPlayerItems(address player) public view returns (uint256[] memory) {
        require(players[player].registered, "Player not registered");
        return playerItems[player];
    }

    function getPlayerBalance() public view returns (uint256) {
        require(players[msg.sender].registered, "Player not registered");
        return players[msg.sender].balance;
    }

    function addFunds(uint256 amount) public {
        require(players[msg.sender].registered, "Player not registered");
        players[msg.sender].balance = players[msg.sender].balance.add(amount);
    }

    function requestRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to pay fee");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        randomResult = randomness;
    }
}