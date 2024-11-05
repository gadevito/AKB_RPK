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

    EnergyTransaction[] public transactions;
    mapping(address => EnergyTransaction) public buyerOrders;
    mapping(address => EnergyTransaction) public sellerOrders;

    event BuyOrderPlaced(address indexed buyer, uint256 energyQuantity, uint256 price);
    event SellOrderPlaced(address indexed seller, uint256 energyQuantity, uint256 price);
    event TransactionExecuted(address indexed buyer, address indexed seller, uint256 energyQuantity, uint256 price, uint256 totalPrice);

    modifier onlyAuthorized() {
        // Logic for onlyAuthorized modifier
        _;
    }

    constructor() public {
        // Default constructor
    }

function placeBuyOrder(uint256 energyQuantity, uint256 price) public onlyAuthorized {
    require(energyQuantity > 0, "Energy quantity must be greater than zero");
    require(price > 0, "Price must be greater than zero");

    EnergyTransaction storage newOrder = buyerOrders[msg.sender];
    newOrder.buyer = msg.sender;
    newOrder.seller = address(0);
    newOrder.energyQuantity = energyQuantity;
    newOrder.price = price;
    newOrder.executed = false;

    emit BuyOrderPlaced(msg.sender, energyQuantity, price);
}


function placeSellOrder(uint256 energyQuantity, uint256 price) public onlyAuthorized {
    require(energyQuantity > 0, "Energy quantity must be greater than zero");
    require(price > 0, "Price must be greater than zero");

    EnergyTransaction storage existingOrder = sellerOrders[msg.sender];
    require(existingOrder.executed || existingOrder.seller == address(0), "Active order already exists");

    EnergyTransaction memory newOrder;
    newOrder.buyer = address(0);
    newOrder.seller = msg.sender;
    newOrder.energyQuantity = energyQuantity;
    newOrder.price = price;
    newOrder.executed = false;

    sellerOrders[msg.sender] = newOrder;

    uint256 index = transactions.length;
    transactions.push();
    EnergyTransaction storage transaction = transactions[index];
    transaction.buyer = newOrder.buyer;
    transaction.seller = newOrder.seller;
    transaction.energyQuantity = newOrder.energyQuantity;
    transaction.price = newOrder.price;
    transaction.executed = newOrder.executed;

    emit SellOrderPlaced(msg.sender, energyQuantity, price);
}


function executeTransaction(address buyer, address seller) public onlyAuthorized {
    // Retrieve the buyer's order
    EnergyTransaction storage buyerOrder = buyerOrders[buyer];

    // Retrieve the seller's order
    EnergyTransaction storage sellerOrder = sellerOrders[seller];

    // Ensure the energy quantity and price match between the buyer's and seller's orders
    require(buyerOrder.energyQuantity == sellerOrder.energyQuantity, "Energy quantity does not match");
    require(buyerOrder.price == sellerOrder.price, "Price does not match");

    // Ensure the transaction has not already been executed
    require(!buyerOrder.executed, "Buyer's order already executed");
    require(!sellerOrder.executed, "Seller's order already executed");

    // Calculate the total price
    uint256 totalPrice = buyerOrder.energyQuantity * buyerOrder.price;

    // Update the transaction status to executed
    buyerOrder.executed = true;
    sellerOrder.executed = true;

    // Add the transaction to the transactions array
    EnergyTransaction storage newTransaction = transactions.push();
    newTransaction.buyer = buyer;
    newTransaction.seller = seller;
    newTransaction.energyQuantity = buyerOrder.energyQuantity;
    newTransaction.price = buyerOrder.price;
    newTransaction.executed = true;

    // Emit the TransactionExecuted event
    emit TransactionExecuted(buyer, seller, buyerOrder.energyQuantity, buyerOrder.price, totalPrice);
}


}