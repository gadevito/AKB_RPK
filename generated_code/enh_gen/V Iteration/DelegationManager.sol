pragma solidity >=0.4.22 <0.9.0;

import "./hardhat/DelegationStorage3.sol";

contract DelegationManager is DelegationStorage3 {
    // Events
    event UserAdded(address indexed user);
    event InstitutionAdded(address indexed institution);
    event ServiceAdded(address indexed institution, string service);
    event DelegationIssued(address indexed from, address indexed to, address indexed institution, string service);
    event DelegationRevoked(address indexed from, address indexed to, address indexed institution, string service);

    // Modifiers
    modifier onlyAuthorizedUser() {
        require(authorizedUsers[msg.sender], "Caller is not an authorized user");
        _;
    }

    modifier onlyAuthorizedInstitution() {
        require(authorizedInstitutions[msg.sender], "Caller is not an authorized institution");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    // Constructor
    constructor() public {
        // Default constructor
    }

    function addUser(address user) public onlyOwner {
        require(!authorizedUsers[user], "User is already authorized");

        authorizedUsers[user] = true;

        emit UserAdded(user);
    }

    function addInstitution(address institution) public onlyOwner {
        require(!authorizedInstitutions[institution], "Institution is already authorized");

        authorizedInstitutions[institution] = true;

        emit InstitutionAdded(institution);
    }

    function addService(string memory service) public onlyAuthorizedInstitution {
        bytes32 hashedService = keccak256(abi.encodePacked(service));
        address institution = msg.sender;

        bool serviceExists = institutionServices[institution][hashedService];
        require(!serviceExists, "Service already exists for this institution");

        institutionServices[institution][hashedService] = true;

        emit ServiceAdded(institution, service);
    }

    function issueDelegation(address from, address to, address institution, string memory service) public onlyAuthorizedUser {
        // Check if the `from` address is an authorized user
        bool isAuthorizedUser = authorizedUsers[from];
        require(isAuthorizedUser, "The 'from' address is not an authorized user");

        // Verify that the `institution` is an authorized institution
        bool isAuthorizedInstitution = authorizedInstitutions[institution];
        require(isAuthorizedInstitution, "The institution is not authorized");

        // Hash the `service` string to get its `bytes32` representation
        bytes32 hashedService = keccak256(abi.encodePacked(service));

        // Check if the hashed service exists in the `institutionServices` mapping for the given institution
        bool serviceExists = institutionServices[institution][hashedService];
        require(serviceExists, "The service does not exist for the given institution");

        // Add the delegation to the `users` mapping
        users[from][institution].services[hashedService].isDelegated[to] = true;

        // Emit the `DelegationIssued` event with the `from`, `to`, `institution`, and `service` parameters
        emit DelegationIssued(from, to, institution, service);
    }

    function revokeDelegation(address to, address institution, string memory service) public onlyAuthorizedUser {
        bytes32 hashedService = hash(service);

        // Check if the delegation exists
        Institution storage institutionDelegations = users[msg.sender][institution];
        bool serviceExists = institutionServices[institution][hashedService];
        require(serviceExists, "Service does not exist for the institution");

        // Ensure the caller is the user who issued the delegation
        bool delegationExists = institutionDelegations.services[hashedService].isDelegated[to];
        require(delegationExists, "Delegation does not exist");

        // Remove the delegation
        institutionDelegations.services[hashedService].isDelegated[to] = false;

        // Emit the DelegationRevoked event
        emit DelegationRevoked(msg.sender, to, institution, service);
    }

    function checkDelegation(address from, address to, address institution, string memory service) public view returns (bool) {
        bytes32 hashedService = keccak256(abi.encodePacked(service));

        bool serviceExists = institutionServices[institution][hashedService];
        if (!serviceExists) {
            return false;
        }

        Institution storage institutionDelegations = users[from][institution];
        bool delegationExists = institutionDelegations.services[hashedService].isDelegated[to];

        return delegationExists;
    }

    function getUserDelegations(address user, address institution) public view returns (string[] memory) {
        // Ensure the institution is authorized
        require(authorizedInstitutions[institution], "Institution is not authorized");

        // Initialize a dynamic array to store the services
        string[] memory services = new string[](0);
        uint256 serviceCount = 0;

        // Iterate through the services of the institution
        for (uint256 i = 0; i < users[user][institution].allServices.length; i = i + 1) {
            bytes32 serviceHash = users[user][institution].allServices[i];

            // Check if the user has issued a delegation for this service
            if (users[user][institution].services[serviceHash].isDelegated[user]) {
                // Resize the array and add the service
                string[] memory tempServices = new string[](serviceCount + 1);
                for (uint256 j = 0; j < serviceCount; j = j + 1) {
                    tempServices[j] = services[j];
                }
                tempServices[serviceCount] = bytes32ToString(serviceHash);
                services = tempServices;
                serviceCount = serviceCount + 1;
            }
        }

        return services;
    }

    function getInstitutionDelegations(address user, address institution) public view returns (string[] memory) {
        require(authorizedInstitutions[institution], "Institution is not authorized");
        require(authorizedUsers[user], "User is not authorized");

        // Initialize a dynamic array to store the services
        string[] memory services = new string[](0);
        uint256 serviceCount = 0;

        // Iterate through the services of the specified institution
        for (uint256 i = 0; i < users[user][institution].allServices.length; i++) {
            bytes32 serviceHash = users[user][institution].allServices[i];
            if (users[user][institution].services[serviceHash].isDelegated[user]) {
                // Resize the array and add the service
                string[] memory tempServices = new string[](serviceCount + 1);
                for (uint256 j = 0; j < serviceCount; j++) {
                    tempServices[j] = services[j];
                }
                tempServices[serviceCount] = bytes32ToString(serviceHash);
                services = tempServices;
                serviceCount++;
            }
        }

        // Return the array of services
        return services;
    }

    function isValidService(address institution, string memory service) public view returns (bool) {
        bytes32 hashedService = keccak256(abi.encodePacked(service));
        bool serviceExists = institutionServices[institution][hashedService];
        return serviceExists;
    }

    function isAuthorizedUser(address user) public view onlyOwner returns (bool) {
        return authorizedUsers[user];
    }

    function isAuthorizedInstitution(address institution) public view onlyOwner returns (bool) {
        bool isAuthorized = authorizedInstitutions[institution];
        return isAuthorized;
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}