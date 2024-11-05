pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract EnergyTrading is Ownable {
    struct EnergyTransaction {
        address buyer;
        address seller;
        uint256 energyQuantity;
        uint256 price;
        bool executed;
    }

    mapping(uint256 => EnergyTransaction) public transactions;
    uint256 public transactionCount;

    event BuyOrderPlaced(uint256 transactionId, address buyer, uint256 energyQuantity, uint256 price);
    event TransactionExecuted(uint256 transactionId, address buyer, address seller, uint256 totalPrice);

    constructor() public {
        // Default constructor
    }

function placeBuyOrder(uint256 energyQuantity, uint256 price) public {
    require(energyQuantity > 0, "Energy quantity must be greater than zero");
    require(price > 0, "Price must be greater than zero");

    transactionCount = transactionCount + 1;
    uint256 newTransactionId = transactionCount;

    EnergyTransaction storage newTransaction = transactions[newTransactionId];
    newTransaction.buyer = msg.sender;
    newTransaction.seller = address(0);
    newTransaction.energyQuantity = energyQuantity;
    newTransaction.price = price;
    newTransaction.executed = false;

    emit BuyOrderPlaced(newTransactionId, msg.sender, energyQuantity, price);
}


function executeTransaction(uint256 transactionId) public {
    // Retrieve the transaction details
    EnergyTransaction storage transaction = transactions[transactionId];

    // Ensure the transaction exists and has not already been executed
    require(transaction.buyer != address(0), "Transaction does not exist");
    require(transaction.executed == false, "Transaction already executed");

    // Ensure the caller is either the buyer or the seller
    require(msg.sender == transaction.buyer || msg.sender == transaction.seller, "Caller is not authorized");

    // Calculate the total price
    uint256 totalPrice = transaction.energyQuantity * transaction.price;

    // Ensure the buyer has sufficient balance to cover the total price
    require(address(transaction.buyer).balance >= totalPrice, "Insufficient balance");

    // Transfer the total price from the buyer to the seller
    (bool success,) = payable(transaction.seller).call{value: totalPrice}("");
    require(success, "Transfer failed");

    // Mark the transaction as executed
    transaction.executed = true;

    // Emit the TransactionExecuted event
    emit TransactionExecuted(transactionId, transaction.buyer, transaction.seller, totalPrice);
}


}