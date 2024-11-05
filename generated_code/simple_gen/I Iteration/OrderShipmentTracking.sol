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

    modifier validOtp(uint256 otpPin) {
        require(otpPin >= 1000 && otpPin <= 9999, "OTP pin must be between 1000 and 9999");
        _;
    }

    constructor() {
        owner = msg.sender;
        deliveredOrdersCount = 0;
    }

    function addOrder(address customer, uint256 otpPin) public onlyOwner validOtp(otpPin) {
        orders[customer].push(Order({
            otpPin: otpPin,
            isDispatched: false,
            isDelivered: false
        }));
    }

    function markAsDispatched(address customer, uint256 orderIndex, uint256 otpPin) public onlyOwner validOtp(otpPin) {
        require(orderIndex < orders[customer].length, "Invalid order index");
        Order storage order = orders[customer][orderIndex];
        require(order.otpPin == otpPin, "Invalid OTP pin");
        order.isDispatched = true;
    }

    function markAsAccepted(uint256 orderIndex, uint256 otpPin) public validOtp(otpPin) {
        require(orderIndex < orders[msg.sender].length, "Invalid order index");
        Order storage order = orders[msg.sender][orderIndex];
        require(order.isDispatched, "Order must be dispatched before it can be accepted");
        require(order.otpPin == otpPin, "Invalid OTP pin");
        order.isDelivered = true;
        deliveredOrdersCount++;
    }

    function checkOrderStatus(uint256 orderIndex) public view returns (bool isDispatched, bool isDelivered) {
        require(orderIndex < orders[msg.sender].length, "Invalid order index");
        Order storage order = orders[msg.sender][orderIndex];
        return (order.isDispatched, order.isDelivered);
    }

    function getCompletedShipments(address customer) public view returns (uint256[] memory, bool[] memory, bool[] memory) {
        uint256 completedCount = 0;
        for (uint256 i = 0; i < orders[customer].length; i++) {
            if (orders[customer][i].isDelivered) {
                completedCount++;
            }
        }

        uint256[] memory otpPins = new uint256[](completedCount);
        bool[] memory isDispatched = new bool[](completedCount);
        bool[] memory isDelivered = new bool[](completedCount);
        uint256 index = 0;
        for (uint256 i = 0; i < orders[customer].length; i++) {
            if (orders[customer][i].isDelivered) {
                otpPins[index] = orders[customer][i].otpPin;
                isDispatched[index] = orders[customer][i].isDispatched;
                isDelivered[index] = orders[customer][i].isDelivered;
                index++;
            }
        }

        return (otpPins, isDispatched, isDelivered);
    }
}