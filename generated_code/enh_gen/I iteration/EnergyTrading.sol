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
    mapping(address => EnergyTransaction) public buyOrders;
    mapping(address => EnergyTransaction) public sellOrders;

    event BuyOrderPlaced(address indexed buyer, uint256 energyQuantity, uint256 price);
    event SellOrderPlaced(address indexed seller, uint256 energyQuantity, uint256 price);
    event TransactionExecuted(address indexed buyer, address indexed seller, uint256 energyQuantity, uint256 price, uint256 totalPrice);

    constructor() public {
        // Default constructor
    }

function placeBuyOrder(uint256 energyQuantity, uint256 price) public {
    require(energyQuantity > 0, "Energy quantity must be greater than zero");
    require(price > 0, "Price must be greater than zero");
    require(buyOrders[msg.sender].executed == false, "Active buy order already exists");

    EnergyTransaction storage newOrder = buyOrders[msg.sender];
    newOrder.buyer = msg.sender;
    newOrder.seller = address(0);
    newOrder.energyQuantity = energyQuantity;
    newOrder.price = price;
    newOrder.executed = false;

    emit BuyOrderPlaced(msg.sender, energyQuantity, price);
}


function placeSellOrder(uint256 energyQuantity, uint256 price) public {
    require(energyQuantity > 0, "Energy quantity must be greater than zero");
    require(price > 0, "Price must be greater than zero");

    EnergyTransaction storage newSellOrder = sellOrders[msg.sender];
    newSellOrder.buyer = address(0);
    newSellOrder.seller = msg.sender;
    newSellOrder.energyQuantity = energyQuantity;
    newSellOrder.price = price;
    newSellOrder.executed = false;

    emit SellOrderPlaced(msg.sender, energyQuantity, price);
}


function executeTransaction(address buyer, address seller) public onlyOwner {
    // Retrieve the buy order and sell order
    EnergyTransaction storage buyOrder = buyOrders[buyer];
    EnergyTransaction storage sellOrder = sellOrders[seller];

    // Check if the buyer and seller addresses match the respective orders
    require(buyOrder.buyer == buyer, "Buyer address mismatch");
    require(sellOrder.seller == seller, "Seller address mismatch");

    // Ensure that the energy quantity and price match between the buy and sell orders
    require(buyOrder.energyQuantity == sellOrder.energyQuantity, "Energy quantity mismatch");
    require(buyOrder.price == sellOrder.price, "Price mismatch");

    // Ensure the transaction has not already been executed
    require(!buyOrder.executed && !sellOrder.executed, "Transaction already executed");

    // Calculate the total price
    uint256 totalPrice = buyOrder.energyQuantity * buyOrder.price;

    // Update the transaction status to executed
    buyOrder.executed = true;
    sellOrder.executed = true;

    // Emit the TransactionExecuted event
    emit TransactionExecuted(buyer, seller, buyOrder.energyQuantity, buyOrder.price, totalPrice);
}


}