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

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier beforeEndDate() {
        require(block.timestamp < endDate, "Charity has ended");
        _;
    }

    modifier afterEndDate() {
        require(block.timestamp >= endDate, "Charity is still ongoing");
        _;
    }

    constructor(uint _goal, uint _endDate, uint _minimumAmount) {
        admin = msg.sender;
        goal = _goal;
        endDate = _endDate;
        minimumAmount = _minimumAmount;
    }

    function contribute() public payable beforeEndDate {
        require(msg.value >= minimumAmount, "Contribution is below the minimum amount");

        if (contributions[msg.sender] == 0) {
            numberOfContributors++;
        }

        contributions[msg.sender] += msg.value;
        totalFundsRaised += msg.value;
    }

    function getRefund() public afterEndDate {
        require(totalFundsRaised < goal, "Goal was reached, no refunds available");
        require(contributions[msg.sender] > 0, "No contributions found for this address");

        uint amountToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(amountToRefund);
    }

    function createSpendingRequest(string memory _description, address payable _recipient, uint _amount) public onlyAdmin {
        require(totalFundsRaised >= goal, "Goal not reached yet");

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