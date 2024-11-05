pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CharityFund {
    using SafeMath for uint;

    address public admin;
    uint public goal;
    uint public endDate;
    uint public minDonation;
    uint public totalRaised;
    uint public numContributors;

    mapping(address => uint) public contributors;
    Request[] public requests;

    struct Request {
        string description;
        address recipient;
        uint amount;
        uint numVoters;
        bool completed;
        mapping(address => bool) votes;
    }

    event DonationReceived(address indexed donor, uint amount);
    event RequestCreated(uint requestId, string description, address recipient, uint amount);
    event RequestVoted(uint requestId, address voter);
    event RequestCompleted(uint requestId);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function");
        _;
    }

    modifier onlyContributor() {
        require(contributors[msg.sender] > 0, "Only a contributor can call this function");
        _;
    }

    modifier goalReached() {
        require(totalRaised >= goal, "The goal must be reached to call this function");
        _;
    }

    modifier beforeEndDate() {
        require(block.timestamp < endDate, "The current time must be before the end date");
        _;
    }

    constructor(uint _goal, uint _endDate, uint _minDonation) {
        admin = msg.sender;
        goal = _goal;
        endDate = _endDate;
        minDonation = _minDonation;
    }

function contribute() public payable beforeEndDate {
    require(msg.value >= minDonation, "Donation amount is less than the minimum required");

    uint contribution = contributors[msg.sender];
    if (contribution == 0) {
        numContributors = numContributors + 1;
    }

    contributors[msg.sender] = contribution + msg.value;
    totalRaised = totalRaised + msg.value;

    emit DonationReceived(msg.sender, msg.value);
}


function refund() public onlyContributor {
    require(block.timestamp > endDate, "Refunds are only available after the end date");
    require(totalRaised < goal, "Refunds are not available if the goal is reached");

    uint contributedAmount = contributors[msg.sender];
    require(contributedAmount > 0, "No contributions to refund");

    contributors[msg.sender] = 0;
    totalRaised = totalRaised - contributedAmount;

    (bool success,) = payable(msg.sender).call{value: contributedAmount}("");
    require(success, "Refund transfer failed");
}


function createRequest(string memory _description, address _recipient, uint _amount) public onlyAdmin goalReached {
    require(_amount <= totalRaised, "Requested amount exceeds total raised funds");

    Request storage newRequest = requests.push();
    newRequest.description = _description;
    newRequest.recipient = _recipient;
    newRequest.amount = _amount;
    newRequest.numVoters = 0;
    newRequest.completed = false;

    uint requestId = requests.length - 1;
    emit RequestCreated(requestId, _description, _recipient, _amount);
}


function voteRequest(uint requestId) public onlyContributor {
    // Check if the requestId is valid
    require(requestId < requests.length, "Invalid request ID");

    // Retrieve the request
    Request storage request = requests[requestId];

    // Ensure the contributor has not already voted on this request
    require(!request.votes[msg.sender], "Contributor has already voted on this request");

    // Record the vote
    request.votes[msg.sender] = true;

    // Increment the number of voters for the request
    request.numVoters = request.numVoters + 1;

    // Emit the RequestVoted event
    emit RequestVoted(requestId, msg.sender);
}


function completeRequest(uint requestId) public onlyAdmin goalReached {
    // Retrieve the spending request using requestId
    Request storage request = requests[requestId];

    // Ensure the request has not already been completed
    require(!request.completed, "Request already completed");

    // Calculate the required number of votes (e.g., a majority of contributors)
    uint requiredVotes = numContributors / 2;

    // Check if the request has enough votes
    require(request.numVoters > requiredVotes, "Not enough votes to complete the request");

    // Transfer the requested amount to the recipient
    (bool success,) = payable(request.recipient).call{value: request.amount}("");
    require(success, "Transfer to recipient failed");

    // Mark the request as completed
    request.completed = true;

    // Emit the RequestCompleted event
    emit RequestCompleted(requestId);
}


function getTotalRaised() public view returns (uint) {
    return totalRaised;
}


}