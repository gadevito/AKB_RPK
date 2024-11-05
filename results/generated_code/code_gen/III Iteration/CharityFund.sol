pragma solidity >=0.4.22 <0.9.0;

contract CharityFund {
    address public admin;
    uint public goal;
    uint public endDate;
    uint public minDonation;
    uint public totalContributors;
    uint public totalFunds;

    mapping(address => uint) public contributors;
    SpendingRequest[] public spendingRequests;

    struct SpendingRequest {
        string description;
        address recipient;
        uint amount;
        uint voterCount;
        bool completed;
        mapping(address => bool) votes;
    }

    event DonationReceived(address indexed donor, uint amount);
    event RefundIssued(address indexed donor, uint amount);
    event SpendingRequestCreated(uint requestId, string description, address recipient, uint amount);
    event SpendingRequestVoted(uint requestId, address indexed voter);
    event SpendingRequestCompleted(uint requestId);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyBeforeEnd() {
        require(block.timestamp < endDate, "Function can only be called before the end date");
        _;
    }

    modifier onlyAfterEnd() {
        require(block.timestamp >= endDate, "Function can only be called after the end date");
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
    newRequest.voterCount = 0;
    newRequest.completed = false;

    uint requestId = spendingRequests.length - 1;
    emit SpendingRequestCreated(requestId, _description, _recipient, _amount);
}


function voteOnSpendingRequest(uint requestId) public {
    // Check if the requestId is valid
    require(requestId < spendingRequests.length, "Invalid request ID");

    // Ensure the caller has contributed to the charity
    require(contributors[msg.sender] > 0, "Caller has not contributed");

    // Retrieve the spending request
    SpendingRequest storage request = spendingRequests[requestId];

    // Ensure the caller has not already voted on this spending request
    require(!request.votes[msg.sender], "Caller has already voted");

    // Record the vote
    request.votes[msg.sender] = true;

    // Increment the number of voters for the spending request
    request.voterCount = request.voterCount + 1;

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
    require(request.voterCount > totalContributorsTemp / 2, "Not enough votes");

    // Transfer the requested amount to the recipient
    address recipientTemp = request.recipient;
    uint amountTemp = request.amount;
    (bool success,) = payable(recipientTemp).call{value: amountTemp}("");
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