pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Lottery {
    using SafeMath for uint;

    address public manager;
    address[] public participants;
    uint public constant minimumContribution = 0.01 ether;

    event WinnerSelected(address indexed winner, uint amount);

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }

    constructor() {
        manager = msg.sender;
    }

function participate() public payable {
    require(msg.value >= minimumContribution, "Minimum contribution is 0.01 ether");

    address[] storage tempParticipants = participants;
    tempParticipants.push(msg.sender);
}


function selectWinner() public onlyManager {
    require(participants.length > 0, "No participants in the lottery");

    // Generate a random index
    uint randomIndex = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length))) % participants.length;

    // Select the winner
    address winner = participants[randomIndex];

    // Transfer the entire balance to the winner
    uint prizeAmount = address(this).balance;
    (bool success,) = payable(winner).call{value: prizeAmount}("");
    require(success, "Transfer failed");

    // Emit the WinnerSelected event
    emit WinnerSelected(winner, prizeAmount);

    // Reset the participants array
    while (participants.length > 0) {
        participants.pop();
    }
}


function getParticipants() public view returns (address[] memory) {
    return participants;
}


function getManager() public view returns (address) {
    return manager;
}


}