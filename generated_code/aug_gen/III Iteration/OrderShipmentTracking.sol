pragma solidity >=0.4.22 <0.9.0;

contract OrderShipmentTracking {
    address public owner;
    uint256 public deliveredOrdersCount;

    enum OrderStatus { Pending, Dispatched, Delivered }

    struct Order {
        uint256 otp;
        OrderStatus status;
    }

    mapping(address => Order[]) public orders;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier validOTP(uint256 _otp) {
        require(_otp >= 1000 && _otp <= 9999, "OTP must be between 1000 and 9999");
        _;
    }

    constructor() {
        owner = msg.sender;
        deliveredOrdersCount = 0;
    }

    function createOrder(address _customer, uint256 _otp) public onlyOwner validOTP(_otp) {
        orders[_customer].push(Order({
            otp: _otp,
            status: OrderStatus.Pending
        }));
    }

    function markAsDispatched(address _customer, uint256 _otp) public onlyOwner validOTP(_otp) {
        Order[] storage customerOrders = orders[_customer];
        for (uint256 i = 0; i < customerOrders.length; i++) {
            if (customerOrders[i].otp == _otp && customerOrders[i].status == OrderStatus.Pending) {
                customerOrders[i].status = OrderStatus.Dispatched;
                break;
            }
        }
    }

    function markAsAccepted(uint256 _otp) public validOTP(_otp) {
        Order[] storage customerOrders = orders[msg.sender];
        for (uint256 i = 0; i < customerOrders.length; i++) {
            if (customerOrders[i].otp == _otp && customerOrders[i].status == OrderStatus.Dispatched) {
                customerOrders[i].status = OrderStatus.Delivered;
                deliveredOrdersCount++;
                break;
            }
        }
    }

    function checkOrderStatus() public view returns (OrderStatus[] memory) {
        Order[] storage customerOrders = orders[msg.sender];
        OrderStatus[] memory statuses = new OrderStatus[](customerOrders.length);
        for (uint256 i = 0; i < customerOrders.length; i++) {
            statuses[i] = customerOrders[i].status;
        }
        return statuses;
    }

    function getCompletedShipments(address _customer) public view returns (uint256[] memory, uint256[] memory, uint256, uint256) {
        Order[] storage customerOrders = orders[_customer];
        uint256 completedCount = 0;
        uint256 pendingCount = 0;
        for (uint256 i = 0; i < customerOrders.length; i++) {
            if (customerOrders[i].status == OrderStatus.Delivered) {
                completedCount++;
            } else {
                pendingCount++;
            }
        }

        uint256[] memory completedOtps = new uint256[](completedCount);
        uint256[] memory completedStatuses = new uint256[](completedCount);
        uint256 index = 0;
        for (uint256 i = 0; i < customerOrders.length; i++) {
            if (customerOrders[i].status == OrderStatus.Delivered) {
                completedOtps[index] = customerOrders[i].otp;
                completedStatuses[index] = uint256(customerOrders[i].status);
                index++;
            }
        }
        return (completedOtps, completedStatuses, customerOrders.length, pendingCount);
    }
}