pragma solidity >=0.4.22 <0.9.0;

contract Voting {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
    }

    address public admin;
    bytes32 public topic;
    bool public votingActive;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public minParticipation;
    uint256 public totalVotes;
    uint256 public totalVoters;

    mapping(address => Voter) public voters;
    mapping(bytes32 => uint256) public votes;
    bytes32[] public choices;

    event VoterRegistered(address voter);
    event VoteCasted(address voter, bytes32 choice);
    event VotingEnded();

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyRegistered() {
        require(voters[msg.sender].isRegistered, "Only registered voters can call this function");
        _;
    }

    modifier onlyActive() {
        require(votingActive, "Voting is not active");
        _;
    }

    constructor(bytes32 _topic, uint256 _minParticipation, uint256 _startTime, uint256 _endTime) {
        admin = msg.sender;
        topic = _topic;
        minParticipation = _minParticipation;
        startTime = _startTime;
        endTime = _endTime;
        votingActive = false;
    }

    function registerVoter(address _voter) public onlyAdmin {
        require(!voters[_voter].isRegistered, "Voter is already registered");
        voters[_voter].isRegistered = true;
        totalVoters++;
        emit VoterRegistered(_voter);
    }

    function startVoting() public onlyAdmin {
        require(!votingActive, "Voting is already active");
        require(block.timestamp >= startTime, "Voting start time has not been reached");
        votingActive = true;
    }

    function endVoting() public onlyAdmin {
        require(votingActive, "Voting is not active");
        require(block.timestamp >= endTime, "Voting end time has not been reached");
        votingActive = false;
        emit VotingEnded();
    }

    function castVote(bytes32 _choice) public onlyRegistered onlyActive {
        require(!voters[msg.sender].hasVoted, "Voter has already voted");
        voters[msg.sender].hasVoted = true;
        votes[_choice]++;
        totalVotes++;
        if (votes[_choice] == 1) {
            choices.push(_choice);
        }
        emit VoteCasted(msg.sender, _choice);
    }

    function getResult() public view returns (bytes32 winner, uint256 winningVotes) {
        require(!votingActive, "Voting is still active");
        require(totalVotes >= minParticipation, "Minimum participation threshold not met");

        bytes32 leadingChoice;
        uint256 leadingVotes = 0;
        bool tie = false;

        for (uint256 i = 0; i < choices.length; i++) {
            bytes32 choice = choices[i];
            if (votes[choice] > leadingVotes) {
                leadingVotes = votes[choice];
                leadingChoice = choice;
                tie = false;
            } else if (votes[choice] == leadingVotes) {
                tie = true;
            }
        }

        require(!tie, "There is a tie between choices");

        return (leadingChoice, leadingVotes);
    }
}