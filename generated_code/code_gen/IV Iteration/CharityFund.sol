pragma solidity >=0.4.22 <0.9.0;

contract CharityFund {
    address public admin;
    uint public goal;
    uint public endDate;
    uint public minAmount;
    uint public totalRaised;
    uint public numContributors;
    mapping(address => uint) public contributors;

    struct SpendingRequest {
        string description;
        address recipient;
        uint amount;
        uint numVoters;
        bool completed;
        address[] votes;
    }

    SpendingRequest[] public spendingRequests;

    event ContributionReceived(address indexed contributor, uint amount);
    event RefundIssued(address indexed contributor, uint amount);
    event SpendingRequestCreated(uint requestId, string description, address recipient, uint amount);
    event SpendingRequestCompleted(uint requestId);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    constructor(uint _goal, uint _endDate, uint _minAmount) {
        admin = msg.sender;
        goal = _goal;
        endDate = _endDate;
        minAmount = _minAmount;
    }

function contribute() public payable {
    require(msg.value >= minAmount, "Contribution is less than the minimum amount");

    uint previousBalance = contributors[msg.sender];
    contributors[msg.sender] = previousBalance + msg.value;

    totalRaised = totalRaised + msg.value;

    if (previousBalance == 0) {
        numContributors = numContributors + 1;
    }

    emit ContributionReceived(msg.sender, msg.value);
}


function refund() public {
    require(block.timestamp > endDate, "Charity has not ended yet");
    require(totalRaised < goal, "Goal has been reached, no refunds available");

    uint contribution = contributors[msg.sender];
    require(contribution > 0, "No contributions found for the caller");

    contributors[msg.sender] = 0;

    (bool success,) = payable(msg.sender).call{value: contribution}("");
    require(success, "Refund transfer failed");

    emit RefundIssued(msg.sender, contribution);
}


function createSpendingRequest(string memory _description, address _recipient, uint _amount) public onlyAdmin {
    require(totalRaised >= goal, "Goal not reached");

    SpendingRequest storage newRequest = spendingRequests.push();
    newRequest.description = _description;
    newRequest.recipient = _recipient;
    newRequest.amount = _amount;
    newRequest.numVoters = 0;
    newRequest.completed = false;

    emit SpendingRequestCreated(spendingRequests.length - 1, _description, _recipient, _amount);
}


function voteOnSpendingRequest(uint requestId) public {
    // Check if the requestId is valid
    require(requestId < spendingRequests.length, "Invalid request ID");

    // Ensure the caller has contributed to the charity
    uint contribution = contributors[msg.sender];
    require(contribution > 0, "Caller has not contributed");

    // Retrieve the spending request
    SpendingRequest storage request = spendingRequests[requestId];

    // Ensure the caller has not already voted on this spending request
    bool hasVoted = false;
    for (uint i = 0; i < request.votes.length; i++) {
        if (request.votes[i] == msg.sender) {
            hasVoted = true;
            break;
        }
    }
    require(!hasVoted, "Caller has already voted");

    // Record the vote by adding the caller's address to the votes of the spending request
    request.votes.push(msg.sender);

    // Increment the number of voters for the spending request
    request.numVoters = request.numVoters + 1;
}


function completeSpendingRequest(uint requestId) public onlyAdmin {
    // Check if the requestId is within bounds
    require(requestId < spendingRequests.length, "Invalid request ID");

    // Retrieve the spending request
    SpendingRequest storage request = spendingRequests[requestId];

    // Ensure the spending request has not already been completed
    require(!request.completed, "Request already completed");

    // Ensure the spending request has enough votes (more than 50% of the contributors)
    require(request.numVoters > numContributors / 2, "Not enough votes");

    // Transfer the requested amount to the recipient
    (bool success,) = payable(request.recipient).call{value: request.amount}("");
    require(success, "Transfer failed");

    // Mark the spending request as completed
    request.completed = true;

    // Emit the SpendingRequestCompleted event
    emit SpendingRequestCompleted(requestId);
}


function getTotalRaised() public view returns (uint) {
    return totalRaised;
}


function getGoal() public view returns (uint) {
    return goal;
}


function getEndDate() public view returns (uint) {
    return endDate;
}


function getMinAmount() public view returns (uint) {
    return minAmount;
}


function getAdmin() public view returns (address) {
    return admin;
}


}