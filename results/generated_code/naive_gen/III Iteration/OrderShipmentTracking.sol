// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract OrderShipmentTracking {
    address public owner;
    uint256 public deliveredOrdersCount;

    struct Order {
        uint256 otpPin;
        bool isDispatched;
        bool isDelivered;
    }

    mapping(address => Order[]) public orders;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier validOtp(uint256 _otpPin) {
        require(_otpPin >= 1000 && _otpPin <= 9999, "OTP must be between 1000 and 9999");
        _;
    }

    constructor() {
        owner = msg.sender;
        deliveredOrdersCount = 0;
    }

    function addOrder(address _customer, uint256 _otpPin) public onlyOwner validOtp(_otpPin) {
        orders[_customer].push(Order({
            otpPin: _otpPin,
            isDispatched: false,
            isDelivered: false
        }));
    }

    function markAsDispatched(address _customer, uint256 _otpPin) public onlyOwner validOtp(_otpPin) {
        Order[] storage customerOrders = orders[_customer];
        for (uint256 i = 0; i < customerOrders.length; i++) {
            if (customerOrders[i].otpPin == _otpPin && !customerOrders[i].isDispatched) {
                customerOrders[i].isDispatched = true;
                break;
            }
        }
    }

    function markAsAccepted(uint256 _otpPin) public validOtp(_otpPin) {
        Order[] storage customerOrders = orders[msg.sender];
        for (uint256 i = 0; i < customerOrders.length; i++) {
            if (customerOrders[i].otpPin == _otpPin && customerOrders[i].isDispatched && !customerOrders[i].isDelivered) {
                customerOrders[i].isDelivered = true;
                deliveredOrdersCount++;
                break;
            }
        }
    }

    function checkOrderStatus() public view returns (bool[] memory) {
        Order[] storage customerOrders = orders[msg.sender];
        bool[] memory statuses = new bool[](customerOrders.length);
        for (uint256 i = 0; i < customerOrders.length; i++) {
            statuses[i] = customerOrders[i].isDispatched && !customerOrders[i].isDelivered;
        }
        return statuses;
    }

    function getCompletedShipments(address _customer) public view returns (Order[] memory) {
        Order[] storage customerOrders = orders[_customer];
        uint256 completedCount = 0;
        for (uint256 i = 0; i < customerOrders.length; i++) {
            if (customerOrders[i].isDelivered) {
                completedCount++;
            }
        }

        Order[] memory completedOrders = new Order[](completedCount);
        uint256 index = 0;
        for (uint256 i = 0; i < customerOrders.length; i++) {
            if (customerOrders[i].isDelivered) {
                completedOrders[index] = customerOrders[i];
                index++;
            }
        }
        return completedOrders;
    }
}