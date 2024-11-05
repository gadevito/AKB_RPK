pragma solidity >=0.4.22 <0.9.0;

contract SubscriptionService {
    address public owner;
    uint256 public subscriptionFee;
    uint256 public interval;
    mapping(address => uint256) public subscriptionExpiry;

    event SubscriptionRenewed(address indexed subscriber, uint256 newExpiry);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    constructor(uint256 _subscriptionFee, uint256 _interval) {
        owner = msg.sender;
        subscriptionFee = _subscriptionFee;
        interval = _interval;
    }

    function setSubscriptionFee(uint256 _newFee) external onlyOwner {
        subscriptionFee = _newFee;
    }

    function subscribe() external payable {
        require(msg.value == subscriptionFee, "Incorrect subscription fee");
        require(subscriptionExpiry[msg.sender] <= block.timestamp, "Subscription still active");

        subscriptionExpiry[msg.sender] = block.timestamp + interval;
        emit SubscriptionRenewed(msg.sender, subscriptionExpiry[msg.sender]);
    }

    function checkSubscription(address _subscriber) external view returns (uint256) {
        return subscriptionExpiry[_subscriber];
    }

    function renewSubscription() external payable {
        require(msg.value == subscriptionFee, "Incorrect subscription fee");
        require(subscriptionExpiry[msg.sender] > block.timestamp, "Subscription expired, please subscribe first");

        subscriptionExpiry[msg.sender] += interval;
        emit SubscriptionRenewed(msg.sender, subscriptionExpiry[msg.sender]);
    }
}