pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract TeamContract is AccessControl {
    address public teamOwner;
    mapping(address => Player) public players;
    address[] public playerAddresses;
    bytes32 public constant TEAM_OWNER = keccak256("TEAM_OWNER");

    struct Player {
        string name;
        uint age;
        string position;
        uint salary;
        uint contractDuration;
    }

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

function addPlayer(address playerAddress, string memory name, uint age, string memory position, uint salary, uint contractDuration) public onlyTeamOwner {
    require(playerAddress != address(0), "Invalid player address");
    require(bytes(name).length > 0, "Player name cannot be empty");
    require(players[playerAddress].age == 0, "Player already exists");

    Player storage newPlayer = players[playerAddress];
    newPlayer.name = name;
    newPlayer.age = age;
    newPlayer.position = position;
    newPlayer.salary = salary;
    newPlayer.contractDuration = contractDuration;

    playerAddresses.push(playerAddress);

    emit PlayerAdded(playerAddress, name, age, position, salary, contractDuration);
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