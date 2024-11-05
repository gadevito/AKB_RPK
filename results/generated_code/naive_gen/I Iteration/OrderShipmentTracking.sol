// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract OrderShipmentTracking {
    address public owner;
    uint256 public deliveredOrdersCount;

    struct Order {
        uint256 otpPin;
        bool dispatched;
        bool delivered;
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
            dispatched: false,
            delivered: false
        }));
    }

    function markAsDispatched(address _customer, uint256 _otpPin) public onlyOwner validOtp(_otpPin) {
        Order[] storage customerOrders = orders[_customer];
        for (uint256 i = 0; i < customerOrders.length; i++) {
            if (customerOrders[i].otpPin == _otpPin && !customerOrders[i].dispatched) {
                customerOrders[i].dispatched = true;
                break;
            }
        }
    }

    function markAsAccepted(address _customer, uint256 _otpPin) public {
        Order[] storage customerOrders = orders[_customer];
        for (uint256 i = 0; i < customerOrders.length; i++) {
            if (customerOrders[i].otpPin == _otpPin && customerOrders[i].dispatched && !customerOrders[i].delivered) {
                customerOrders[i].delivered = true;
                deliveredOrdersCount++;
                break;
            }
        }
    }

    function checkOrderStatus(address _customer) public view returns (bool[] memory) {
        Order[] storage customerOrders = orders[_customer];
        bool[] memory statuses = new bool[](customerOrders.length);
        for (uint256 i = 0; i < customerOrders.length; i++) {
            statuses[i] = customerOrders[i].dispatched && !customerOrders[i].delivered;
        }
        return statuses;
    }

    function getCompletedShipments(address _customer) public view returns (uint256[] memory, bool[] memory, bool[] memory) {
        Order[] storage customerOrders = orders[_customer];
        uint256 completedCount = 0;
        for (uint256 i = 0; i < customerOrders.length; i++) {
            if (customerOrders[i].delivered) {
                completedCount++;
            }
        }

        uint256[] memory otpPins = new uint256[](completedCount);
        bool[] memory dispatchedStatuses = new bool[](completedCount);
        bool[] memory deliveredStatuses = new bool[](completedCount);
        uint256 index = 0;
        for (uint256 i = 0; i < customerOrders.length; i++) {
            if (customerOrders[i].delivered) {
                otpPins[index] = customerOrders[i].otpPin;
                dispatchedStatuses[index] = customerOrders[i].dispatched;
                deliveredStatuses[index] = customerOrders[i].delivered;
                index++;
            }
        }
        return (otpPins, dispatchedStatuses, deliveredStatuses);
    }
}