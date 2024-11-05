pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TeamContract is Ownable {
    address public teamOwner;

    struct Player {
        string name;
        uint age;
        string position;
        uint salary;
        uint contractDuration;
    }

    mapping(address => Player) public players;
    address[] public playerAddresses;

    event PlayerAdded(address indexed playerAddress, string name);
    event PlayerRemoved(address indexed playerAddress);

    modifier onlyTeamOwner() {
        require(msg.sender == teamOwner, "Caller is not the team owner");
        _;
    }

    constructor(address _teamOwner) {
        teamOwner = _teamOwner;
    }

function addPlayer(address _playerAddress, string memory _name, uint _age, string memory _position, uint _salary, uint _contractDuration) public onlyTeamOwner {
    // Check if the player already exists
    Player storage existingPlayer = players[_playerAddress];
    require(bytes(existingPlayer.name).length == 0, "Player already exists");

    // Create a new Player struct and set fields individually
    Player storage newPlayer = players[_playerAddress];
    newPlayer.name = _name;
    newPlayer.age = _age;
    newPlayer.position = _position;
    newPlayer.salary = _salary;
    newPlayer.contractDuration = _contractDuration;

    // Append the player's address to the playerAddresses array
    playerAddresses.push(_playerAddress);

    // Emit the PlayerAdded event
    emit PlayerAdded(_playerAddress, _name);
}


function removePlayer(address playerAddress) public onlyTeamOwner {
    // Check if the player exists in the players mapping
    Player storage player = players[playerAddress];
    require(bytes(player.name).length != 0, "Player does not exist");

    // Remove the player from the players mapping
    player.name = "";
    player.age = 0;
    player.position = "";
    player.salary = 0;
    player.contractDuration = 0;

    // Find and remove the player's address from the playerAddresses array
    uint length = playerAddresses.length;
    for (uint i = 0; i < length; i = i + 1) {
        if (playerAddresses[i] == playerAddress) {
            playerAddresses[i] = playerAddresses[length - 1];
            playerAddresses.pop();
            break;
        }
    }

    // Emit the PlayerRemoved event with the player's address
    emit PlayerRemoved(playerAddress);
}


function getPlayer(address playerAddress) public view returns (string memory name, uint age, string memory position, uint salary, uint contractDuration) {
    Player storage player = players[playerAddress];
    require(bytes(player.name).length != 0, "Player does not exist");

    name = player.name;
    age = player.age;
    position = player.position;
    salary = player.salary;
    contractDuration = player.contractDuration;
}


function getAllPlayers() public view returns (Player[] memory) {
    uint length = playerAddresses.length;
    Player[] memory allPlayers = new Player[](length);

    for (uint i = 0; i < length; i = i + 1) {
        address playerAddress = playerAddresses[i];
        Player storage player = players[playerAddress];

        allPlayers[i] = Player({
            name: player.name,
            age: player.age,
            position: player.position,
            salary: player.salary,
            contractDuration: player.contractDuration
        });
    }

    return allPlayers;
}


}