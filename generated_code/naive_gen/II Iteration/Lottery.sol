// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Lottery {
    address public manager;
    address[] public participants;
    uint public constant MINIMUM_CONTRIBUTION = 0.01 ether;

    event WinnerSelected(address indexed winner, uint prizeAmount);

    constructor() {
        manager = msg.sender;
    }

    modifier restricted() {
        require(msg.sender == manager, "Only the manager can call this function");
        _;
    }

    function participate() public payable {
        require(msg.value >= MINIMUM_CONTRIBUTION, "Minimum contribution is 0.01 ether");
        participants.push(msg.sender);
    }

    function getParticipants() public view returns (address[] memory) {
        return participants;
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants)));
    }

    function selectWinner() public restricted {
        require(participants.length > 0, "No participants in the lottery");

        uint index = random() % participants.length;
        address winner = participants[index];
        uint prizeAmount = address(this).balance;

        // Ensure the winner address is payable
        payable(winner).transfer(prizeAmount);

        emit WinnerSelected(winner, prizeAmount);

        // Reset the participants array for the next round
        participants = new address[](0);
    }
}