// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ShipmentService {
    address public owner;

    struct Order {
        uint pin;
        bool dispatched;
        bool delivered;
    }

    mapping(address => Order[]) public orders;
    mapping(address => uint) public completedDeliveries;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyCustomer() {
        require(msg.sender != owner, "Owner cannot call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function shipWithPin(address customerAddress, uint pin) public onlyOwner {
        require(
            pin >= 1000 && pin <= 9999,
            "PIN must be a 4-digit number between 1000 and 9999"
        );
        orders[customerAddress].push(Order(pin, true, false));
    }

    function acceptOrder(uint pin) public onlyCustomer {
        Order[] storage customerOrders = orders[msg.sender];
        for (uint i = 0; i < customerOrders.length; i++) {
            if (
                customerOrders[i].dispatched &&
                !customerOrders[i].delivered &&
                customerOrders[i].pin == pin
            ) {
                customerOrders[i].delivered = true;
                completedDeliveries[msg.sender]++;
                break;
            }
        }
    }

    function checkStatus(
        address customerAddress
    ) public view onlyCustomer returns (uint) {
        require(
            msg.sender == customerAddress,
            "Customers can only check their own orders"
        );
        Order[] storage customerOrders = orders[customerAddress];
        uint enRouteCount = 0;
        for (uint i = 0; i < customerOrders.length; i++) {
            if (customerOrders[i].dispatched && !customerOrders[i].delivered) {
                enRouteCount++;
            }
        }
        return enRouteCount;
    }

    function totalCompletedDeliveries(
        address customerAddress
    ) public view returns (uint) {
        return completedDeliveries[customerAddress];
    }
}
