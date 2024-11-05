// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract OrderShipmentTracking {
    address public owner;
    uint256 public deliveredOrdersCount;

    struct Order {
        uint16 otpPin;
        bool isDispatched;
        bool isDelivered;
    }

    mapping(address => Order[]) public orders;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier validOtp(uint16 otpPin) {
        require(otpPin >= 1000 && otpPin <= 9999, "OTP must be between 1000 and 9999");
        _;
    }

    constructor() {
        owner = msg.sender;
        deliveredOrdersCount = 0;
    }

    function addOrder(address customer, uint16 otpPin) public onlyOwner validOtp(otpPin) {
        orders[customer].push(Order({
            otpPin: otpPin,
            isDispatched: false,
            isDelivered: false
        }));
    }

    function markAsDispatched(address customer, uint256 orderIndex, uint16 otpPin) public onlyOwner validOtp(otpPin) {
        require(orderIndex < orders[customer].length, "Invalid order index");
        Order storage order = orders[customer][orderIndex];
        require(order.otpPin == otpPin, "Invalid OTP");
        order.isDispatched = true;
    }

    function markAsAccepted(uint256 orderIndex, uint16 otpPin) public validOtp(otpPin) {
        require(orderIndex < orders[msg.sender].length, "Invalid order index");
        Order storage order = orders[msg.sender][orderIndex];
        require(order.otpPin == otpPin, "Invalid OTP");
        require(order.isDispatched, "Order must be dispatched before it can be accepted");
        order.isDelivered = true;
        deliveredOrdersCount++;
    }

    function checkOrderStatus(uint256 orderIndex) public view returns (bool isDispatched, bool isDelivered) {
        require(orderIndex < orders[msg.sender].length, "Invalid order index");
        Order storage order = orders[msg.sender][orderIndex];
        return (order.isDispatched, order.isDelivered);
    }

    function getCompletedShipments(address customer) public view returns (Order[] memory) {
        uint256 completedCount = 0;
        for (uint256 i = 0; i < orders[customer].length; i++) {
            if (orders[customer][i].isDelivered) {
                completedCount++;
            }
        }

        Order[] memory completedOrders = new Order[](completedCount);
        uint256 index = 0;
        for (uint256 i = 0; i < orders[customer].length; i++) {
            if (orders[customer][i].isDelivered) {
                completedOrders[index] = orders[customer][i];
                index++;
            }
        }

        return completedOrders;
    }
}