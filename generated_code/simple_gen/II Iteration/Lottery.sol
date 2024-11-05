pragma solidity >=0.4.22 <0.9.0;

contract Lottery {
    address public manager;
    address[] public participants;
    uint public minimumContribution = 0.01 ether;

    event WinnerSelected(address indexed winner, uint prizeAmount);

    constructor() {
        manager = msg.sender;
    }

    function participate() public payable {
        require(msg.value >= minimumContribution, "Minimum contribution is 0.01 ether");
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

        payable(winner).transfer(prizeAmount);

        emit WinnerSelected(winner, prizeAmount);

        participants = new address[](0);
    }

    modifier restricted() {
        require(msg.sender == manager, "Only the manager can call this function");
        _;
    }
}