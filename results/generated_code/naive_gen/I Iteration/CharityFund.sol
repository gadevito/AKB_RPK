// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract CharityFund {
    struct SpendingRequest {
        string description;
        address payable recipient;
        uint amount;
        uint numberOfVoters;
        bool completed;
    }

    address public admin;
    uint public goal;
    uint public endDate;
    uint public minimumDonation;
    uint public numberOfContributors;
    uint public totalFundsRaised;
    mapping(address => uint) public contributions;
    SpendingRequest[] public spendingRequests;
    mapping(uint => mapping(address => bool)) public votes; // Mapping to store votes for each request

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
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

    constructor(uint _goal, uint _endDate, uint _minimumDonation) {
        admin = msg.sender;
        goal = _goal;
        endDate = _endDate;
        minimumDonation = _minimumDonation;
    }

    function contribute() public payable beforeEndDate {
        require(msg.value >= minimumDonation, "Donation amount is less than minimum donation");
        if (contributions[msg.sender] == 0) {
            numberOfContributors++;
        }
        contributions[msg.sender] += msg.value;
        totalFundsRaised += msg.value;
    }

    function requestRefund() public afterEndDate {
        require(totalFundsRaised < goal, "Goal was reached, no refunds available");
        uint contributedAmount = contributions[msg.sender];
        require(contributedAmount > 0, "No contributions found for this address");
        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(contributedAmount);
    }

    function createSpendingRequest(string memory _description, address payable _recipient, uint _amount) public onlyAdmin {
        require(totalFundsRaised >= goal, "Cannot create spending request before reaching the goal");
        SpendingRequest memory newRequest = SpendingRequest({
            description: _description,
            recipient: _recipient,
            amount: _amount,
            numberOfVoters: 0,
            completed: false
        });
        spendingRequests.push(newRequest);
    }

    function voteOnSpendingRequest(uint _requestId) public {
        require(contributions[msg.sender] > 0, "Only contributors can vote");
        require(!votes[_requestId][msg.sender], "You have already voted on this request");
        votes[_requestId][msg.sender] = true;
        spendingRequests[_requestId].numberOfVoters++;
    }

    function completeSpendingRequest(uint _requestId) public onlyAdmin {
        SpendingRequest storage request = spendingRequests[_requestId];
        require(!request.completed, "Request already completed");
        require(request.numberOfVoters > numberOfContributors / 2, "Not enough votes to complete the request");
        require(address(this).balance >= request.amount, "Not enough funds to complete the request");
        request.completed = true;
        request.recipient.transfer(request.amount);
    }

    function getTotalFundsRaised() public view returns (uint) {
        return totalFundsRaised;
    }

    function getSpendingRequest(uint _requestId) public view returns (string memory, address, uint, uint, bool) {
        SpendingRequest storage request = spendingRequests[_requestId];
        return (request.description, request.recipient, request.amount, request.numberOfVoters, request.completed);
    }
}