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
    uint public minimumDonation;
    uint public numberOfContributors;
    uint public totalFundsRaised;
    mapping(address => uint) public contributions;
    SpendingRequest[] public spendingRequests;
    mapping(uint => address[]) public requestVoters;

    event ContributionReceived(address indexed contributor, uint amount);
    event RefundIssued(address indexed contributor, uint amount);
    event SpendingRequestCreated(uint indexed requestId, string description, address recipient, uint amount);
    event VoteCast(address indexed voter, uint indexed requestId);
    event SpendingRequestCompleted(uint indexed requestId, address recipient, uint amount);

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
        emit ContributionReceived(msg.sender, msg.value);
    }

    function requestRefund() public afterEndDate {
        require(totalFundsRaised < goal, "Goal has been reached, no refunds available");
        uint contributedAmount = contributions[msg.sender];
        require(contributedAmount > 0, "No contributions found for this address");
        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(contributedAmount);
        emit RefundIssued(msg.sender, contributedAmount);
    }

    function createSpendingRequest(string memory _description, address payable _recipient, uint _amount) public onlyAdmin {
        require(totalFundsRaised >= goal, "Cannot create spending request before reaching the goal");
        SpendingRequest storage newRequest = spendingRequests.push();
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.amount = _amount;
        newRequest.numberOfVoters = 0;
        newRequest.completed = false;
        emit SpendingRequestCreated(spendingRequests.length - 1, _description, _recipient, _amount);
    }

    function voteOnSpendingRequest(uint _requestId) public {
        require(contributions[msg.sender] > 0, "Only contributors can vote");
        SpendingRequest storage request = spendingRequests[_requestId];
        require(!request.votes[msg.sender], "You have already voted on this request");
        request.votes[msg.sender] = true;
        request.numberOfVoters++;
        requestVoters[_requestId].push(msg.sender);
        emit VoteCast(msg.sender, _requestId);
    }

    function completeSpendingRequest(uint _requestId) public onlyAdmin {
        SpendingRequest storage request = spendingRequests[_requestId];
        require(request.numberOfVoters > numberOfContributors / 2, "Not enough votes to complete the request");
        require(!request.completed, "Request already completed");
        require(address(this).balance >= request.amount, "Not enough funds to complete the request");
        request.completed = true;
        request.recipient.transfer(request.amount);
        emit SpendingRequestCompleted(_requestId, request.recipient, request.amount);
    }

    function getCharityDetails() public view returns (uint, uint, uint, address) {
        return (goal, endDate, minimumDonation, admin);
    }

    function getTotalFundsRaised() public view returns (uint) {
        return totalFundsRaised;
    }

    function getSpendingRequestDetails(uint _requestId) public view returns (string memory, address, uint, uint, bool, address[] memory) {
        SpendingRequest storage request = spendingRequests[_requestId];
        return (request.description, request.recipient, request.amount, request.numberOfVoters, request.completed, requestVoters[_requestId]);
    }

    receive() external payable {
        contribute();
    }
}