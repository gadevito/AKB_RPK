pragma solidity >=0.4.22 <0.9.0;

contract Election {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
    }

    address public admin;
    bytes32 public topic;
    bool public votingActive;
    uint public minimumParticipation;
    uint public totalVotes;
    uint public totalVoters;

    mapping(address => Voter) public voters;
    mapping(bytes32 => uint) public votes;
    bytes32[] public choices; // Array to store the choices

    event VoterRegistered(address voter);
    event VoteCasted(address voter, bytes32 choice);
    event VotingEnded();

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyRegistered() {
        require(voters[msg.sender].isRegistered, "Only registered voters can perform this action");
        _;
    }

    modifier onlyActive() {
        require(votingActive, "Voting is not active");
        _;
    }

    constructor(bytes32 _topic, uint _minimumParticipation) {
        admin = msg.sender;
        topic = _topic;
        votingActive = true;
        minimumParticipation = _minimumParticipation;
    }

    function registerVoter(address _voter) public onlyAdmin {
        require(!voters[_voter].isRegistered, "Voter is already registered");
        voters[_voter].isRegistered = true;
        totalVoters++;
        emit VoterRegistered(_voter);
    }

    function startVoting() public onlyAdmin {
        votingActive = true;
    }

    function endVoting() public onlyAdmin {
        votingActive = false;
        emit VotingEnded();
    }

    function castVote(bytes32 _choice) public onlyRegistered onlyActive {
        require(!voters[msg.sender].hasVoted, "Voter has already voted");
        voters[msg.sender].hasVoted = true;
        votes[_choice]++;
        totalVotes++;
        emit VoteCasted(msg.sender, _choice);

        // Add the choice to the choices array if it's the first vote for this choice
        if (votes[_choice] == 1) {
            choices.push(_choice);
        }
    }

    function getResult() public view returns (bytes32 winner, uint winnerVotes) {
        require(!votingActive, "Voting is still active");
        require(totalVotes >= minimumParticipation, "Minimum participation not reached");

        bytes32 leadingChoice;
        uint leadingVotes = 0;

        for (uint i = 0; i < choices.length; i++) {
            if (votes[choices[i]] > leadingVotes) {
                leadingVotes = votes[choices[i]];
                leadingChoice = choices[i];
            }
        }

        return (leadingChoice, leadingVotes);
    }
}