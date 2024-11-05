pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EnergyTrading {
    using SafeMath for uint256;

    address public owner;

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
    event TransactionExecuted(address indexed buyer, address indexed seller, uint256 energyQuantity, uint256 price);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

function placeBuyOrder(uint256 energyQuantity, uint256 price) public {
    require(energyQuantity > 0, "Energy quantity must be greater than zero");
    require(price > 0, "Price must be greater than zero");

    EnergyTransaction storage newTransaction = buyerOrders[msg.sender];
    newTransaction.buyer = msg.sender;
    newTransaction.seller = address(0);
    newTransaction.energyQuantity = energyQuantity;
    newTransaction.price = price;
    newTransaction.executed = false;

    emit BuyOrderPlaced(msg.sender, energyQuantity, price);
}


function placeSellOrder(uint256 energyQuantity, uint256 price) public {
    require(energyQuantity > 0, "Energy quantity must be greater than zero");
    require(price > 0, "Price must be greater than zero");

    EnergyTransaction storage newOrder = sellerOrders[msg.sender];
    newOrder.buyer = address(0);
    newOrder.seller = msg.sender;
    newOrder.energyQuantity = energyQuantity;
    newOrder.price = price;
    newOrder.executed = false;

    emit SellOrderPlaced(msg.sender, energyQuantity, price);
}


function executeTransaction(address buyer, address seller) public onlyOwner {
    // Fetch buyer and seller orders
    EnergyTransaction storage buyerOrder = buyerOrders[buyer];
    EnergyTransaction storage sellerOrder = sellerOrders[seller];

    // Ensure both buyer and seller have placed orders
    require(buyerOrder.energyQuantity > 0, "Buyer has not placed an order");
    require(sellerOrder.energyQuantity > 0, "Seller has not placed an order");

    // Ensure the energy quantity and price match
    require(buyerOrder.energyQuantity == sellerOrder.energyQuantity, "Energy quantities do not match");
    require(buyerOrder.price == sellerOrder.price, "Prices do not match");

    // Calculate the total price
    uint256 totalPrice = buyerOrder.energyQuantity * buyerOrder.price;

    // Update the executed status of the transaction
    buyerOrder.executed = true;
    sellerOrder.executed = true;

    // Transfer the total price from buyer to seller
    (bool success,) = payable(seller).call{value: totalPrice}("");
    require(success, "Transfer failed");

    // Emit the TransactionExecuted event
    emit TransactionExecuted(buyer, seller, buyerOrder.energyQuantity, buyerOrder.price);
}


}