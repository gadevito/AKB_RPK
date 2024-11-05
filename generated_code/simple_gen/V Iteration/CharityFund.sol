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
    uint public minimumAmount;
    uint public numberOfContributors;
    uint public totalFundsRaised;
    mapping(address => uint) public contributions;
    SpendingRequest[] public spendingRequests;
    mapping(uint => mapping(address => bool)) public votes; // Mapping to track votes for each request

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

        uint amount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function createSpendingRequest(string memory _description, address payable _recipient, uint _amount) public onlyAdmin {
        require(totalFundsRaised >= goal, "Goal not reached yet");
        require(_amount <= totalFundsRaised, "Requested amount exceeds total funds raised");

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
        require(_requestId < spendingRequests.length, "Invalid request ID");
        require(contributions[msg.sender] > 0, "Only contributors can vote");
        require(!votes[_requestId][msg.sender], "You have already voted on this request");
        require(!spendingRequests[_requestId].completed, "Request already completed");

        votes[_requestId][msg.sender] = true;
        spendingRequests[_requestId].numberOfVoters++;
    }

    function completeSpendingRequest(uint _requestId) public onlyAdmin {
        require(_requestId < spendingRequests.length, "Invalid request ID");
        SpendingRequest storage request = spendingRequests[_requestId];
        require(!request.completed, "Request already completed");
        require(request.numberOfVoters > numberOfContributors / 2, "Not enough votes to complete the request");
        require(request.amount <= address(this).balance, "Request amount exceeds available funds");

        request.completed = true;
        request.recipient.transfer(request.amount);
    }

    function getTotalFundsRaised() public view returns (uint) {
        return totalFundsRaised;
    }
}