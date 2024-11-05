// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LotterySystem {
    address public manager; // Address of the manager who initiates the lottery
    address[] public players; // Array to store addresses of participants

    event LotteryWinner(address winner, uint256 prize); // Event emitted when a winner is picked

    constructor() {
        manager = msg.sender; // Set the deployer of the contract as the initial manager
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }

    function enter() public payable {
        require(msg.value > .01 ether, "Minimum contribution is 0.01 ether"); // Require a minimum contribution of 0.01 ether

        players.push(msg.sender); // Add the participant's address to the players array
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, players)
                )
            ); // Generate a pseudo-random number based on block data and player addresses
    }

    function pickWinner() public onlyManager {
        uint256 index = random() % players.length; // Generate a random index within the range of players array
        address winner = players[index]; // Get the address of the winner
        uint256 prize = address(this).balance; // Get the current balance of the contract (prize pool)

        (bool success, ) = winner.call{value: prize}(""); // Transfer the entire prize pool to the winner
        require(success, "Transfer failed"); // Ensure the transfer is successful

        emit LotteryWinner(winner, prize); // Emit an event to announce the winner

        // Reset the players array for the next round
        players = new address[](0);
    }
}
