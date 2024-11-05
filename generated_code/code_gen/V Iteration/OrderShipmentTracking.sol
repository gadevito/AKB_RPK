pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract OrderShipmentTracking {
    using SafeMath for uint;

    address public owner;
    uint public orderCounter;
    uint public deliveredOrderCounter;

    struct Order {
        uint otp;
        bool dispatched;
        bool delivered;
        address customer;
    }

    mapping(uint => Order) public orders;

    event OrderDispatched(uint orderId);
    event OrderDelivered(uint orderId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyCustomer(uint orderId) {
        require(msg.sender == orders[orderId].customer, "Only the customer can call this function");
        _;
    }

    constructor() public {
        owner = msg.sender;
        orderCounter = 0;
        deliveredOrderCounter = 0;
    }

function createOrder(uint _otp, address _customer) public onlyOwner {
    require(_otp >= 1000 && _otp <= 9999, "OTP must be between 1000 and 9999");

    orderCounter = orderCounter + 1;

    Order storage newOrder = orders[orderCounter];
    newOrder.otp = _otp;
    newOrder.dispatched = false;
    newOrder.delivered = false;
    newOrder.customer = _customer;
}


function markAsDispatched(uint orderId, uint otp) public onlyOwner {
    // Retrieve the order from the mapping
    Order storage order = orders[orderId];

    // Verify that the provided OTP matches the stored OTP
    require(order.otp == otp, "Incorrect OTP");

    // Check that the order has not already been dispatched
    require(!order.dispatched, "Order already dispatched");

    // Mark the order as dispatched
    order.dispatched = true;

    // Emit the OrderDispatched event
    emit OrderDispatched(orderId);
}


function markAsDelivered(uint orderId, uint otp) public onlyCustomer(orderId) {
    // Check if the order exists
    require(orderId < orderCounter, "Order does not exist");

    // Retrieve the order from the mapping
    Order storage order = orders[orderId];

    // Verify that the order has been dispatched
    require(order.dispatched, "Order has not been dispatched");

    // Verify that the provided OTP matches the OTP stored in the order
    require(order.otp == otp, "Invalid OTP");

    // Verify that the order is not already marked as delivered
    require(!order.delivered, "Order is already delivered");

    // Mark the order as delivered
    order.delivered = true;

    // Increment the deliveredOrderCounter
    deliveredOrderCounter = deliveredOrderCounter + 1;

    // Emit the OrderDelivered event
    emit OrderDelivered(orderId);
}


function checkOrderStatus(uint orderId) public view returns (bool dispatched, bool delivered) {
    require(orderId < orderCounter, "Invalid order ID");

    Order storage order = orders[orderId];
    bool orderDispatched = order.dispatched;
    bool orderDelivered = order.delivered;

    return (orderDispatched, orderDelivered);
}


function getCompletedShipments(address customer) public view returns (uint[] memory) {
    uint[] memory completedShipments = new uint[](orderCounter);
    uint count = 0;

    for (uint i = 1; i <= orderCounter; i = i + 1) {
        Order storage order = orders[i];
        address orderCustomer = order.customer;
        bool orderDelivered = order.delivered;

        if (orderCustomer == customer && orderDelivered) {
            completedShipments[count] = i;
            count = count + 1;
        }
    }

    uint[] memory result = new uint[](count);
    for (uint j = 0; j < count; j = j + 1) {
        result[j] = completedShipments[j];
    }

    return result;
}


}