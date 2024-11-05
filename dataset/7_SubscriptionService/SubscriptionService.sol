// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SubscriptionService {
    address public owner;
    uint256 public subscriptionFee;
    uint256 public interval;
    mapping(address => uint256) public subscriptionExpiry;

    event SubscriptionRenewed(address subscriber, uint256 expiryTimestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
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
        require(msg.value >= subscriptionFee, "Insufficient payment for subscription");
        
        uint256 expiryTimestamp = block.timestamp + interval;
        subscriptionExpiry[msg.sender] = expiryTimestamp;

        emit SubscriptionRenewed(msg.sender, expiryTimestamp);
    }

    function checkSubscription() external view returns (bool) {
        return block.timestamp <= subscriptionExpiry[msg.sender];
    }

    function renewSubscription() external payable {
        require(block.timestamp > subscriptionExpiry[msg.sender], "Subscription is still active");
        require(msg.value >= subscriptionFee, "Insufficient payment for subscription");

        uint256 expiryTimestamp = block.timestamp + interval;
        subscriptionExpiry[msg.sender] = expiryTimestamp;

        emit SubscriptionRenewed(msg.sender, expiryTimestamp);
    }

    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        payable(owner).transfer(balance);
    }
}