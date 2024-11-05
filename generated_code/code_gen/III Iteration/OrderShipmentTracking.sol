pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract OrderShipmentTracking {
    using SafeMath for uint;

    address public owner;
    uint public orderCounter;
    uint public deliveredOrderCounter;

    struct Order {
        uint otpPin;
        bool dispatched;
        bool delivered;
    }

    mapping(uint => Order) public orders;
    mapping(address => uint[]) public customerOrders;

    event OrderDispatched(uint orderId);
    event OrderDelivered(uint orderId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyCustomer() {
        require(customerOrders[msg.sender].length > 0, "Only the customer can call this function");
        _;
    }

    constructor() public {
        owner = msg.sender;
        orderCounter = 0;
        deliveredOrderCounter = 0;
    }

function createOrder(address customer, uint otpPin) public onlyOwner {
    require(otpPin >= 1000 && otpPin <= 9999, "OTP pin must be between 1000 and 9999");

    orderCounter = orderCounter + 1;
    uint newOrderId = orderCounter;

    Order storage newOrder = orders[newOrderId];
    newOrder.otpPin = otpPin;
    newOrder.dispatched = false;
    newOrder.delivered = false;

    customerOrders[customer].push(newOrderId);

    emit OrderDispatched(newOrderId);
}


function markAsDispatched(uint orderId, uint otpPin) public onlyOwner {
    // Check that the otpPin is within the valid range
    require(otpPin >= 1000 && otpPin <= 9999, "Invalid OTP pin");

    // Retrieve the order from the orders mapping
    Order storage order = orders[orderId];

    // Verify that the provided otpPin matches the stored OTP pin
    require(order.otpPin == otpPin, "OTP pin does not match");

    // Check if the order is already dispatched
    require(!order.dispatched, "Order already dispatched");

    // Mark the order as dispatched
    order.dispatched = true;

    // Emit the OrderDispatched event
    emit OrderDispatched(orderId);
}


function markAsDelivered(uint orderId, uint otpPin) public onlyCustomer {
    // Check if the order exists
    Order storage order = orders[orderId];
    require(order.otpPin != 0, "Order does not exist");

    // Verify that the order has been dispatched
    bool dispatched = order.dispatched;
    require(dispatched, "Order has not been dispatched");

    // Verify that the provided otpPin matches the stored OTP pin
    uint storedOtpPin = order.otpPin;
    require(storedOtpPin == otpPin, "Invalid OTP pin");

    // Check if the order is already marked as delivered
    bool delivered = order.delivered;
    require(!delivered, "Order is already delivered");

    // Mark the order as delivered
    order.delivered = true;

    // Increment the deliveredOrderCounter
    deliveredOrderCounter = deliveredOrderCounter + 1;

    // Emit the OrderDelivered event
    emit OrderDelivered(orderId);
}


function checkOrderStatus() public view onlyCustomer returns (uint[] memory) {
    uint[] storage orderIds = customerOrders[msg.sender];
    uint[] memory undeliveredOrders = new uint[](orderIds.length);
    uint count = 0;

    for (uint i = 0; i < orderIds.length; i = i + 1) {
        uint orderId = orderIds[i];
        Order storage order = orders[orderId];

        bool dispatched = order.dispatched;
        bool delivered = order.delivered;

        if (dispatched && !delivered) {
            undeliveredOrders[count] = orderId;
            count = count + 1;
        }
    }

    uint[] memory result = new uint[](count);
    for (uint j = 0; j < count; j = j + 1) {
        result[j] = undeliveredOrders[j];
    }

    return result;
}


function getCompletedShipments(address customer) public view returns (uint[] memory) {
    uint[] memory customerOrderIds = customerOrders[customer];
    uint completedCount = 0;

    // First pass to count the number of completed shipments
    for (uint i = 0; i < customerOrderIds.length; i = i + 1) {
        uint orderId = customerOrderIds[i];
        Order storage order = orders[orderId];
        if (order.delivered) {
            completedCount = completedCount + 1;
        }
    }

    // Initialize the array with the correct size
    uint[] memory completedShipments = new uint[](completedCount);
    uint index = 0;

    // Second pass to populate the array
    for (uint i = 0; i < customerOrderIds.length; i = i + 1) {
        uint orderId = customerOrderIds[i];
        Order storage order = orders[orderId];
        if (order.delivered) {
            completedShipments[index] = orderId;
            index = index + 1;
        }
    }

    return completedShipments;
}


}