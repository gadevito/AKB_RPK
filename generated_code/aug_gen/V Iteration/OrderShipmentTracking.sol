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
        require(otpPin >= 1000 && otpPin <= 9999, "OTP must be between 1000 and 9999");
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

    function markAsDispatched(address customer, uint256 otpPin) public onlyOwner validOtp(otpPin) {
        Order[] storage customerOrders = orders[customer];
        for (uint256 i = 0; i < customerOrders.length; i++) {
            if (customerOrders[i].otpPin == otpPin && !customerOrders[i].isDispatched) {
                customerOrders[i].isDispatched = true;
                break;
            }
        }
    }

    function acceptOrder(uint256 otpPin) public validOtp(otpPin) {
        Order[] storage customerOrders = orders[msg.sender];
        for (uint256 i = 0; i < customerOrders.length; i++) {
            if (customerOrders[i].otpPin == otpPin && customerOrders[i].isDispatched && !customerOrders[i].isDelivered) {
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

    function getCompletedShipments(address customer) public view returns (uint256[] memory, bool[] memory, bool[] memory) {
        Order[] storage customerOrders = orders[customer];
        uint256 completedCount = 0;
        for (uint256 i = 0; i < customerOrders.length; i++) {
            if (customerOrders[i].isDelivered) {
                completedCount++;
            }
        }

        uint256[] memory otpPins = new uint256[](completedCount);
        bool[] memory isDispatched = new bool[](completedCount);
        bool[] memory isDelivered = new bool[](completedCount);
        uint256 index = 0;
        for (uint256 i = 0; i < customerOrders.length; i++) {
            if (customerOrders[i].isDelivered) {
                otpPins[index] = customerOrders[i].otpPin;
                isDispatched[index] = customerOrders[i].isDispatched;
                isDelivered[index] = customerOrders[i].isDelivered;
                index++;
            }
        }
        return (otpPins, isDispatched, isDelivered);
    }
}