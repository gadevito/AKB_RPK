pragma solidity >=0.4.22 <0.9.0;

contract TeamContract {
    address public teamOwner;
    bytes32 public constant TEAM_OWNER = keccak256("TEAM_OWNER");

    struct Player {
        string name;
        uint age;
        string position;
        uint salary;
        uint contractDuration;
    }

    mapping(address => Player) private players;
    address[] private playerAddresses;

    modifier onlyTeamOwner() {
        require(msg.sender == teamOwner, "Caller is not the team owner");
        _;
    }

    constructor(address _teamOwner) {
        teamOwner = _teamOwner;
    }

    function addPlayer(address _playerAddress, string memory _name, uint _age, string memory _position, uint _salary, uint _contractDuration) public onlyTeamOwner {
        require(players[_playerAddress].age == 0, "Player already exists");
        players[_playerAddress] = Player(_name, _age, _position, _salary, _contractDuration);
        playerAddresses.push(_playerAddress);
    }

    function getPlayer(address _playerAddress) public view returns (string memory, uint, string memory, uint, uint) {
        Player memory player = players[_playerAddress];
        return (player.name, player.age, player.position, player.salary, player.contractDuration);
    }

    function getAllPlayers() public view returns (address[] memory, string[] memory, uint[] memory, string[] memory, uint[] memory, uint[] memory) {
        uint length = playerAddresses.length;
        string[] memory names = new string[](length);
        uint[] memory ages = new uint[](length);
        string[] memory positions = new string[](length);
        uint[] memory salaries = new uint[](length);
        uint[] memory contractDurations = new uint[](length);

        for (uint i = 0; i < length; i++) {
            Player memory player = players[playerAddresses[i]];
            names[i] = player.name;
            ages[i] = player.age;
            positions[i] = player.position;
            salaries[i] = player.salary;
            contractDurations[i] = player.contractDuration;
        }

        return (playerAddresses, names, ages, positions, salaries, contractDurations);
    }

    function removePlayer(address _playerAddress) public onlyTeamOwner {
        require(players[_playerAddress].age != 0, "Player does not exist");
        delete players[_playerAddress];

        for (uint i = 0; i < playerAddresses.length; i++) {
            if (playerAddresses[i] == _playerAddress) {
                playerAddresses[i] = playerAddresses[playerAddresses.length - 1];
                playerAddresses.pop();
                break;
            }
        }
    }
}