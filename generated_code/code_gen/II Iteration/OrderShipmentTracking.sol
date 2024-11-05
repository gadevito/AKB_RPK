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
    require(otp >= 1000 && otp <= 9999, "Invalid OTP");

    Order storage order = orders[orderId];

    require(!order.dispatched, "Order already dispatched");
    require(order.otp == otp, "Incorrect OTP");

    order.dispatched = true;

    emit OrderDispatched(orderId);
}


function markAsDelivered(uint orderId, uint otp) public onlyCustomer(orderId) {
    // Verify that the order exists by checking if the orderId is valid
    require(orderId > 0 && orderId <= orderCounter, "Order does not exist");

    // Retrieve the order from the orders mapping
    Order storage order = orders[orderId];

    // Check that the order has been dispatched
    require(order.dispatched == true, "Order has not been dispatched");

    // Verify that the provided OTP matches the OTP stored in the order
    require(order.otp == otp, "Invalid OTP");

    // Check if the order is already marked as delivered
    require(order.delivered == false, "Order is already delivered");

    // Mark the order as delivered
    order.delivered = true;

    // Increment the deliveredOrderCounter
    deliveredOrderCounter = deliveredOrderCounter + 1;

    // Emit the OrderDelivered event
    emit OrderDelivered(orderId);
}


function getOrderStatus(uint orderId) public view returns (bool dispatched, bool delivered) {
    Order storage order = orders[orderId];
    require(order.customer != address(0), "Order does not exist");

    dispatched = order.dispatched;
    delivered = order.delivered;

    return (dispatched, delivered);
}


function getCompletedShipments(address customer) public view returns (uint[] memory) {
    uint[] memory tempArray = new uint[](orderCounter);
    uint count = 0;

    for (uint i = 1; i <= orderCounter; i = i + 1) {
        Order storage order = orders[i];
        if (order.customer == customer && order.delivered) {
            tempArray[count] = i;
            count = count + 1;
        }
    }

    uint[] memory result = new uint[](count);
    for (uint j = 0; j < count; j = j + 1) {
        result[j] = tempArray[j];
    }

    return result;
}


}