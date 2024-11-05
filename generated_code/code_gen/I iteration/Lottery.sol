pragma solidity >=0.4.22 <0.9.0;

contract Lottery {
    address public manager;
    address[] public participants;
    uint public constant minimumContribution = 0.01 ether;

    event WinnerSelected(address indexed winner, uint amount);

    modifier onlyManager() {
        require(msg.sender == manager, "Only the manager can call this function");
        _;
    }

    constructor() {
        manager = msg.sender;
    }

function enter() public payable {
    require(msg.value >= minimumContribution, "Minimum contribution is 0.01 ether");

    address[] storage tempParticipants = participants;
    tempParticipants.push(msg.sender);
}


function pickWinner() public onlyManager {
    require(participants.length > 0, "No participants in the lottery");

    uint randomIndex = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length))) % participants.length;
    address winner = participants[randomIndex];
    uint prizeAmount = address(this).balance;

    (bool success,) = payable(winner).call{value: prizeAmount}("");
    require(success, "Transfer failed");

    emit WinnerSelected(winner, prizeAmount);

    // Reset participants array
    while (participants.length > 0) {
        participants.pop();
    }
}


function getParticipants() public view returns (address[] memory) {
    return participants;
}


function getManager() public view returns (address) {
    address tempManager = manager;
    return tempManager;
}


}