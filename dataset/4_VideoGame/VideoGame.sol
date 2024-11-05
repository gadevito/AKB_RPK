// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VRFConsumerBase.sol";

contract VideoGame is VRFConsumerBase {
    struct Player {
        address playerAddress;
        uint256 level;
        uint256 experience;
        uint256 balance;
    }

    struct Item {
        uint256 id;
        string name;
        uint256 price;
        uint256 rarity;
        address owner;
    }

    mapping(address => Player) public players;
    mapping(uint256 => Item) public items;
    mapping(address => uint256[]) public playerItems;

    uint256 private _nextItemId;
    uint256 public totalPlayers;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;

    event PlayerRegistered(address indexed player, uint256 level, uint256 experience, uint256 balance);
    event ItemCreated(uint256 indexed itemId, string name, uint256 price, uint256 rarity);
    event ItemPurchased(uint256 indexed itemId, address indexed buyer, uint256 price);
    event ItemTransferred(uint256 indexed itemId, address indexed from, address indexed to);

    constructor()
        VRFConsumerBase(
            0x514910771AF9Ca656af840dff83E8264EcF986CA,
            0xAA77729D3466CA35AE8D28A8E15C0B3Ff8b57DA1
        )
    {
        _nextItemId = 1;
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a9e8bcd144365ba0a5f5;
        fee = 0.1 * 10 ** 18;
    }

    modifier onlyRegistered() {
        require(players[msg.sender].playerAddress != address(0), "Player not registered");
        _;
    }

    function registerPlayer() public {
        require(players[msg.sender].playerAddress == address(0), "Player already registered");

        players[msg.sender] = Player({
            playerAddress: msg.sender,
            level: 1,
            experience: 0,
            balance: 1000
        });

        totalPlayers++;
        emit PlayerRegistered(msg.sender, 1, 0, 1000);
    }

    function createItem(string memory _name, uint256 _price) public onlyRegistered {
        uint256 itemId = _nextItemId;
        _nextItemId++;

        requestRandomNumber();

        uint256 rarity = (randomResult % 5) + 1;

        items[itemId] = Item({
            id: itemId,
            name: _name,
            price: _price,
            rarity: rarity,
            owner: address(0)
        });

        emit ItemCreated(itemId, _name, _price, rarity);
    }

    function purchaseItem(uint256 _itemId) public onlyRegistered {
        require(items[_itemId].id == _itemId, "Item does not exist");
        require(items[_itemId].owner == address(0), "Item already owned");
        require(players[msg.sender].balance >= items[_itemId].price, "Insufficient balance");

        players[msg.sender].balance -= items[_itemId].price;

        items[_itemId].owner = msg.sender;
        playerItems[msg.sender].push(_itemId);

        emit ItemPurchased(_itemId, msg.sender, items[_itemId].price);
    }

    function transferItem(uint256 _itemId, address _to) public onlyRegistered {
        require(items[_itemId].id == _itemId, "Item does not exist");
        require(items[_itemId].owner == msg.sender, "You do not own this item");
        require(players[_to].playerAddress != address(0), "Recipient is not registered");

        removeItemFromList(msg.sender, _itemId);

        playerItems[_to].push(_itemId);

        items[_itemId].owner = _to;

        emit ItemTransferred(_itemId, msg.sender, _to);
    }

    function getPlayerDetails(address _player) public view returns (Player memory) {
        return players[_player];
    }

    function getItemDetails(uint256 _itemId) public view returns (Item memory) {
        return items[_itemId];
    }

    function getPlayerItems(address _player) public view returns (uint256[] memory) {
        return playerItems[_player];
    }

    function getPlayerBalance() public view onlyRegistered returns (uint256) {
        return players[msg.sender].balance;
    }

    function addFunds(uint256 _amount) public onlyRegistered {
        players[msg.sender].balance += _amount;
    }

    function removeItemFromList(address _player, uint256 _itemId) internal {
        uint256[] storage itemList = playerItems[_player];
        for (uint256 i = 0; i < itemList.length; i++) {
            if (itemList[i] == _itemId) {
                itemList[i] = itemList[itemList.length - 1];
                itemList.pop();
                break;
            }
        }
    }

    function requestRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }
}