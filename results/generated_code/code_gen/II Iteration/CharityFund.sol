pragma solidity >=0.4.22 <0.9.0;

contract CharityFund {
    address public admin;
    uint public goal;
    uint public endDate;
    uint public minDonation;
    uint public totalContributors;
    uint public totalFunds;

    mapping(address => uint) public contributors;

    struct SpendingRequest {
        string description;
        address recipient;
        uint amount;
        uint votersCount;
        bool completed;
        address[] votes;
    }

    SpendingRequest[] public spendingRequests;

    event DonationReceived(address indexed donor, uint amount);
    event RefundIssued(address indexed contributor, uint amount);
    event SpendingRequestCreated(uint requestId, string description, address recipient, uint amount);
    event SpendingRequestVoted(uint requestId, address indexed voter);
    event SpendingRequestCompleted(uint requestId);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function");
        _;
    }

    modifier onlyBeforeEnd() {
        require(block.timestamp < endDate, "Only callable before the end date");
        _;
    }

    modifier onlyAfterEnd() {
        require(block.timestamp >= endDate, "Only callable after the end date");
        _;
    }

    constructor(uint _goal, uint _endDate, uint _minDonation) {
        admin = msg.sender;
        goal = _goal;
        endDate = _endDate;
        minDonation = _minDonation;
    }

function contribute() public payable onlyBeforeEnd {
    require(msg.value >= minDonation, "Donation amount is less than the minimum required");

    if (contributors[msg.sender] == 0) {
        totalContributors = totalContributors + 1;
    }

    contributors[msg.sender] = contributors[msg.sender] + msg.value;
    totalFunds = totalFunds + msg.value;

    emit DonationReceived(msg.sender, msg.value);
}


function refund() public onlyAfterEnd {
    require(totalFunds < goal, "Goal has been reached, no refunds available");
    uint contribution = contributors[msg.sender];
    require(contribution > 0, "No contributions found for this address");

    contributors[msg.sender] = 0;

    (bool success,) = payable(msg.sender).call{value: contribution}("");
    require(success, "Refund transfer failed");

    emit RefundIssued(msg.sender, contribution);
}


function createSpendingRequest(string memory _description, address _recipient, uint _amount) public onlyAdmin {
    require(totalFunds >= goal, "Goal not reached");

    SpendingRequest storage newRequest = spendingRequests.push();
    newRequest.description = _description;
    newRequest.recipient = _recipient;
    newRequest.amount = _amount;
    newRequest.votersCount = 0;
    newRequest.completed = false;

    uint requestId = spendingRequests.length - 1;
    emit SpendingRequestCreated(requestId, _description, _recipient, _amount);
}


function voteOnSpendingRequest(uint requestId) public {
    // Check if the caller is a contributor
    uint contribution = contributors[msg.sender];
    require(contribution > 0, "Caller is not a contributor");

    // Check if the requestId is valid
    uint spendingRequestsLength = spendingRequests.length;
    require(requestId < spendingRequestsLength, "Invalid requestId");

    // Retrieve the spending request
    SpendingRequest storage request = spendingRequests[requestId];

    // Check if the caller has already voted on this spending request
    bool hasVoted = false;
    for (uint i = 0; i < request.votes.length; i = i + 1) {
        if (request.votes[i] == msg.sender) {
            hasVoted = true;
            break;
        }
    }
    require(!hasVoted, "Caller has already voted on this request");

    // Record the vote
    request.votes.push(msg.sender);

    // Increment the number of voters for the spending request
    request.votersCount = request.votersCount + 1;

    // Emit the SpendingRequestVoted event
    emit SpendingRequestVoted(requestId, msg.sender);
}


function completeSpendingRequest(uint requestId) public onlyAdmin {
    // Check if the requestId is within bounds
    require(requestId < spendingRequests.length, "Invalid requestId");

    // Retrieve the spending request
    SpendingRequest storage request = spendingRequests[requestId];

    // Ensure the spending request has not already been completed
    require(!request.completed, "Request already completed");

    // Check if the number of votes is greater than 50% of the total contributors
    uint totalContributorsTemp = totalContributors;
    require(request.votersCount > totalContributorsTemp / 2, "Not enough votes");

    // Check if the contract balance is sufficient to cover the spending request amount
    uint amount = request.amount;
    require(address(this).balance >= amount, "Insufficient contract balance");

    // Transfer the specified amount to the recipient
    address recipient = request.recipient;
    (bool success,) = payable(recipient).call{value: amount}("");
    require(success, "Transfer failed");

    // Mark the spending request as completed
    request.completed = true;

    // Emit the SpendingRequestCompleted event
    emit SpendingRequestCompleted(requestId);
}


function getTotalFunds() public view returns (uint) {
    return totalFunds;
}


}