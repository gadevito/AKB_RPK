// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract EnergyTrading {
    address public owner;

    struct EnergyTransaction {
        address buyer;
        address seller;
        uint256 energyQuantity;
        uint256 price;
        bool executed;
    }

    mapping(uint256 => EnergyTransaction) public transactions;
    uint256 public transactionCount;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyAuthorized(address _buyer, address _seller) {
        require(msg.sender == _buyer || msg.sender == _seller, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function placeBuyOrder(address _seller, uint256 _energyQuantity, uint256 _price) public payable {
        require(msg.value == _energyQuantity * _price, "Incorrect value sent");

        transactionCount++;
        transactions[transactionCount] = EnergyTransaction({
            buyer: msg.sender,
            seller: _seller,
            energyQuantity: _energyQuantity,
            price: _price,
            executed: false
        });
    }

    function executeTransaction(uint256 _transactionId) public {
        EnergyTransaction storage transaction = transactions[_transactionId];
        require(msg.sender == transaction.buyer || msg.sender == transaction.seller, "Not authorized");
        require(transaction.buyer != address(0) && transaction.seller != address(0), "Invalid transaction participants");
        require(!transaction.executed, "Transaction already executed");

        uint256 totalPrice = transaction.energyQuantity * transaction.price;
        require(address(this).balance >= totalPrice, "Insufficient contract balance");

        transaction.executed = true;
        payable(transaction.seller).transfer(totalPrice);
    }

    function deposit() public payable onlyOwner {}

    function withdraw(uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance");
        payable(owner).transfer(_amount);
    }
}