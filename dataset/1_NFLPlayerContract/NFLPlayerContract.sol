// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./AccessControl.sol";

contract NFLPlayerContract is AccessControl {
    bytes32 public constant TEAM_OWNER = keccak256("TEAM_OWNER");

    struct Player {
        string name;
        uint256 age;
        string position;
        uint256 salary;
        uint256 contractDuration;
    }

    mapping(address => Player) public players;
    address[] public playerAddresses;

    constructor(address teamOwner) {
        _setupRole(TEAM_OWNER, teamOwner);
    }

    function addPlayer(
        address _playerAddress,
        string memory _name,
        uint256 _age,
        string memory _position,
        uint256 _salary,
        uint256 _contractDuration
    ) public onlyRole(TEAM_OWNER) {
        Player memory newPlayer = Player({
            name: _name,
            age: _age,
            position: _position,
            salary: _salary,
            contractDuration: _contractDuration
        });
        players[_playerAddress] = newPlayer;
        playerAddresses.push(_playerAddress);
    }

    function getPlayer(
        address _playerAddress
    ) public view returns (Player memory) {
        return players[_playerAddress];
    }

    function getAllPlayers() public view returns (Player[] memory) {
        Player[] memory allPlayers = new Player[](playerAddresses.length);
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            allPlayers[i] = players[playerAddresses[i]];
        }
        return allPlayers;
    }

    function removePlayer(address _playerAddress) public onlyRole(TEAM_OWNER) {
        delete players[_playerAddress];
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            if (playerAddresses[i] == _playerAddress) {
                playerAddresses[i] = playerAddresses[
                    playerAddresses.length - 1
                ];
                playerAddresses.pop();
                break;
            }
        }
    }
}
