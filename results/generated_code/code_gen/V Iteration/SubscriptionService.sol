pragma solidity >=0.4.22 <0.9.0;

contract SubscriptionService {
    address public owner;
    uint256 public subscriptionFee;
    uint256 public interval;
    mapping(address => uint256) public subscriptionExpiry;

    event SubscriptionRenewed(address indexed subscriber, uint256 expiryTimestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
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

    uint256 currentExpiry = subscriptionExpiry[msg.sender];
    uint256 newExpiry;

    if (currentExpiry > block.timestamp) {
        newExpiry = currentExpiry + interval;
    } else {
        newExpiry = block.timestamp + interval;
    }

    subscriptionExpiry[msg.sender] = newExpiry;

    emit SubscriptionRenewed(msg.sender, newExpiry);
}


function checkSubscription(address _subscriber) public view returns (uint256) {
    uint256 expiryTimestamp = subscriptionExpiry[_subscriber];
    return expiryTimestamp;
}


function renewSubscription() external payable {
    require(msg.value == subscriptionFee, "Incorrect subscription fee");

    uint256 currentExpiry = subscriptionExpiry[msg.sender];
    uint256 newExpiry;

    if (currentExpiry > block.timestamp) {
        newExpiry = currentExpiry + interval;
    } else {
        newExpiry = block.timestamp + interval;
    }

    subscriptionExpiry[msg.sender] = newExpiry;

    emit SubscriptionRenewed(msg.sender, newExpiry);
}


}