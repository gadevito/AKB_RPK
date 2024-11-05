pragma solidity >=0.4.22 <0.9.0;

contract Election {
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
    mapping(address => Voter) public voters;
    mapping(bytes32 => uint) public votes;
    bytes32[] public candidates;
    uint public totalVotes;

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

    constructor(bytes32 _topic, bytes32[] memory _candidates, uint _minParticipation, uint _startTime, uint _endTime) {
        admin = msg.sender;
        topic = _topic;
        votingActive = false;
        candidates = _candidates;
        minParticipation = _minParticipation;
        startTime = _startTime;
        endTime = _endTime;
    }

    function registerVoter(address _voter) public onlyAdmin {
        require(!voters[_voter].isRegistered, "Voter is already registered.");
        voters[_voter] = Voter(true, false);
        emit VoterRegistered(_voter);
    }

    function startVoting() public onlyAdmin {
        require(!votingActive, "Voting is already active.");
        require(block.timestamp >= startTime, "Voting cannot start before the start time.");
        votingActive = true;
    }

    function endVoting() public onlyAdmin {
        require(votingActive, "Voting is not active.");
        require(block.timestamp >= endTime, "Voting cannot end before the end time.");
        votingActive = false;
        emit VotingEnded();
    }

    function castVote(bytes32 _choice) public onlyRegistered onlyActive {
        require(!voters[msg.sender].hasVoted, "Voter has already voted.");
        require(validCandidate(_choice), "Invalid candidate.");
        voters[msg.sender].hasVoted = true;
        votes[_choice]++;
        totalVotes++;
        emit VoteCasted(msg.sender, _choice);
    }

    function getResult() public view returns (bytes32 winner, uint winnerVotes) {
        require(!votingActive, "Voting is still active.");
        require(totalVotes >= minParticipation, "Minimum participation not reached.");
        uint maxVotes = 0;
        for (uint i = 0; i < candidates.length; i++) {
            if (votes[candidates[i]] > maxVotes) {
                maxVotes = votes[candidates[i]];
                winner = candidates[i];
            }
        }
        winnerVotes = maxVotes;
    }

    function validCandidate(bytes32 _candidate) internal view returns (bool) {
        for (uint i = 0; i < candidates.length; i++) {
            if (candidates[i] == _candidate) {
                return true;
            }
        }
        return false;
    }
}