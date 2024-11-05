pragma solidity >=0.4.22 <0.9.0;

contract Voting {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
    }

    address public admin;
    bytes32 public topic;
    bool public votingActive;
    uint public startTime;
    uint public endTime;
    uint public minParticipation;
    uint public totalVotes;
    uint public totalVoters;

    mapping(address => Voter) public voters;
    mapping(bytes32 => uint) public votes;
    bytes32[] public choices;

    event VoterRegistered(address voter);
    event VoteCasted(address voter, bytes32 choice);
    event VotingEnded();

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyRegistered() {
        require(voters[msg.sender].isRegistered, "Only registered voters can call this function.");
        _;
    }

    modifier onlyActive() {
        require(votingActive, "Voting is not active.");
        _;
    }

    constructor(bytes32 _topic, uint _minParticipation) {
        admin = msg.sender;
        topic = _topic;
        votingActive = false;
        minParticipation = _minParticipation;
        totalVotes = 0;
        totalVoters = 0;
    }

    function registerVoter(address _voter) public onlyAdmin {
        require(!voters[_voter].isRegistered, "Voter is already registered.");
        voters[_voter].isRegistered = true;
        totalVoters++;
        emit VoterRegistered(_voter);
    }

    function startVoting(uint _startTime, uint _endTime) public onlyAdmin {
        require(!votingActive, "Voting is already active.");
        require(_startTime < _endTime, "Start time must be before end time.");
        startTime = _startTime;
        endTime = _endTime;
        votingActive = true;
        totalVotes = 0;
        delete choices;
    }

    function endVoting() public onlyAdmin {
        require(votingActive, "Voting is already inactive.");
        require(block.timestamp >= endTime, "Voting period has not ended yet.");
        votingActive = false;
        emit VotingEnded();
    }

    function castVote(bytes32 _choice) public onlyRegistered onlyActive {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Voting is not within the allowed time period.");
        require(!voters[msg.sender].hasVoted, "Voter has already casted a vote.");
        voters[msg.sender].hasVoted = true;
        votes[_choice]++;
        totalVotes++;
        if (votes[_choice] == 1) {
            choices.push(_choice);
        }
        emit VoteCasted(msg.sender, _choice);
    }

    function getResult() public view returns (bytes32 winner, uint winnerVotes) {
        require(!votingActive, "Voting is still active.");
        require(totalVotes >= minParticipation, "Minimum participation threshold not met.");

        bytes32 leadingChoice;
        uint leadingVotes;

        for (uint i = 0; i < choices.length; i++) {
            if (votes[choices[i]] > leadingVotes) {
                leadingChoice = choices[i];
                leadingVotes = votes[choices[i]];
            }
        }

        return (leadingChoice, leadingVotes);
    }
}