pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract TeamContract is AccessControl {
    address public teamOwner;
    bytes32 public constant TEAM_OWNER = keccak256("TEAM_OWNER");

    struct Player {
        string name;
        uint age;
        string position;
        uint salary;
        uint contractDuration;
    }

    mapping(address => Player) public players;
    address[] public playerAddresses;

    event PlayerAdded(address indexed playerAddress, string name, uint age, string position, uint salary, uint contractDuration);
    event PlayerRemoved(address indexed playerAddress);

    modifier onlyTeamOwner() {
        require(hasRole(TEAM_OWNER, msg.sender), "Caller is not the team owner");
        _;
    }

    constructor(address _teamOwner) {
        teamOwner = _teamOwner;
        _setupRole(TEAM_OWNER, _teamOwner);
    }

function addPlayer(address _playerAddress, string memory _name, uint _age, string memory _position, uint _salary, uint _contractDuration) public onlyTeamOwner {
    // Check if the player already exists
    Player storage existingPlayer = players[_playerAddress];
    require(bytes(existingPlayer.name).length == 0, "Player already exists");

    // Create a new Player struct
    Player storage newPlayer = players[_playerAddress];
    newPlayer.name = _name;
    newPlayer.age = _age;
    newPlayer.position = _position;
    newPlayer.salary = _salary;
    newPlayer.contractDuration = _contractDuration;

    // Add the new player to the playerAddresses array
    playerAddresses.push(_playerAddress);

    // Emit the PlayerAdded event
    emit PlayerAdded(_playerAddress, _name, _age, _position, _salary, _contractDuration);
}


function removePlayer(address playerAddress) public onlyTeamOwner {
    // Check if the player exists in the players mapping
    require(players[playerAddress].age != 0, "Player does not exist");

    // Remove the player from the players mapping
    players[playerAddress].name = "";
    players[playerAddress].age = 0;
    players[playerAddress].position = "";
    players[playerAddress].salary = 0;
    players[playerAddress].contractDuration = 0;

    // Remove the player's address from the playerAddresses array
    uint length = playerAddresses.length;
    for (uint i = 0; i < length; i = i + 1) {
        if (playerAddresses[i] == playerAddress) {
            playerAddresses[i] = playerAddresses[length - 1];
            playerAddresses.pop();
            break;
        }
    }

    // Emit the PlayerRemoved event
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