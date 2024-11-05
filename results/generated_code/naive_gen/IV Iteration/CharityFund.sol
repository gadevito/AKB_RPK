// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract CharityFund {
    struct SpendingRequest {
        string description;
        address payable recipient;
        uint amount;
        uint numberOfVoters;
        bool completed;
        mapping(address => bool) votes;
    }

    address public admin;
    uint public goal;
    uint public endDate;
    uint public minimumAmount;
    uint public numberOfContributors;
    uint public totalFundsRaised;
    mapping(address => uint) public contributions;
    SpendingRequest[] public spendingRequests;

    constructor(uint _goal, uint _endDate, uint _minimumAmount) {
        admin = msg.sender;
        goal = _goal;
        endDate = _endDate;
        minimumAmount = _minimumAmount;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyBeforeEndDate() {
        require(block.timestamp < endDate, "Charity has ended");
        _;
    }

    modifier onlyAfterEndDate() {
        require(block.timestamp >= endDate, "Charity is still ongoing");
        _;
    }

    function contribute() public payable onlyBeforeEndDate {
        require(msg.value >= minimumAmount, "Contribution is below the minimum amount");

        if (contributions[msg.sender] == 0) {
            numberOfContributors++;
        }

        contributions[msg.sender] += msg.value;
        totalFundsRaised += msg.value;
    }

    function getRefund() public onlyAfterEndDate {
        require(totalFundsRaised < goal, "Goal was reached, no refunds available");
        require(contributions[msg.sender] > 0, "No contributions to refund");

        uint amountToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(amountToRefund);
    }

    function createSpendingRequest(string memory _description, address payable _recipient, uint _amount) public onlyAdmin {
        require(totalFundsRaised >= goal, "Cannot create spending request before reaching the goal");

        SpendingRequest storage newRequest = spendingRequests.push();
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.amount = _amount;
        newRequest.numberOfVoters = 0;
        newRequest.completed = false;
    }

    function voteOnSpendingRequest(uint _requestId) public {
        require(contributions[msg.sender] > 0, "Only contributors can vote");
        SpendingRequest storage request = spendingRequests[_requestId];
        require(!request.votes[msg.sender], "You have already voted on this request");

        request.votes[msg.sender] = true;
        request.numberOfVoters++;
    }

    function completeSpendingRequest(uint _requestId) public onlyAdmin {
        SpendingRequest storage request = spendingRequests[_requestId];
        require(!request.completed, "Request already completed");
        require(request.numberOfVoters > numberOfContributors / 2, "Not enough votes to complete the request");

        request.completed = true;
        request.recipient.transfer(request.amount);
    }

    function getTotalFundsRaised() public view returns (uint) {
        return totalFundsRaised;
    }
}