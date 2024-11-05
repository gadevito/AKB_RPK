pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EnergyTrading {
    using SafeMath for uint256;

    address public owner;
    EnergyTransaction[] public energyTransactions;
    mapping(address => uint256) public balances;
    address public priceMechanism;

    event BuyOrderPlaced(address indexed buyer, uint256 energyQuantity, uint256 price);
    event TransactionExecuted(address indexed buyer, address indexed seller, uint256 energyQuantity, uint256 totalPrice);
    event PriceMechanismUpdated(address indexed newPriceMechanism);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    struct EnergyTransaction {
        address buyer;
        address seller;
        uint256 energyQuantity;
        uint256 price;
        bool executed;
    }

    constructor() public {
        owner = msg.sender;
    }

function placeBuyOrder(uint256 energyQuantity, uint256 price) public {
    require(energyQuantity > 0, "Energy quantity must be greater than zero");
    require(price > 0, "Price must be greater than zero");

    EnergyTransaction memory newTransaction;
    newTransaction.buyer = msg.sender;
    newTransaction.seller = address(0);
    newTransaction.energyQuantity = energyQuantity;
    newTransaction.price = price;
    newTransaction.executed = false;

    energyTransactions.push(newTransaction);

    emit BuyOrderPlaced(msg.sender, energyQuantity, price);
}


function executeTransaction(uint256 transactionId) public {
    // Retrieve the transaction from energyTransactions using transactionId
    EnergyTransaction storage transaction = energyTransactions[transactionId];

    // Check if the transaction has already been executed
    require(!transaction.executed, "Transaction has already been executed");

    // Ensure the caller is either the buyer or the seller
    require(msg.sender == transaction.buyer || msg.sender == transaction.seller, "Caller is not authorized");

    // Calculate the total price
    uint256 totalPrice = transaction.energyQuantity * transaction.price;

    // Ensure the buyer has sufficient balance to cover the total price
    require(balances[transaction.buyer] >= totalPrice, "Insufficient balance");

    // Transfer the total price from the buyer's balance to the seller's balance
    balances[transaction.buyer] = balances[transaction.buyer] - totalPrice;
    balances[transaction.seller] = balances[transaction.seller] + totalPrice;

    // Mark the transaction as executed
    transaction.executed = true;

    // Emit the TransactionExecuted event
    emit TransactionExecuted(transaction.buyer, transaction.seller, transaction.energyQuantity, totalPrice);
}


function setPriceMechanism(address _priceMechanism) public onlyOwner {
    require(_priceMechanism != address(0), "Invalid address for price mechanism");

    address tempPriceMechanism = _priceMechanism;
    priceMechanism = tempPriceMechanism;

    emit PriceMechanismUpdated(tempPriceMechanism);
}


}