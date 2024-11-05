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

    // Constructor
    constructor() {
        // Default constructor
    }

    function addUser(address user) public {
        require(msg.sender == owner, "Caller is not the owner");
        require(!authorizedUsers[user], "User is already authorized");

        authorizedUsers[user] = true;

        emit UserAdded(user);
    }

    function addInstitution(address institution) public {
        require(msg.sender == owner, "Caller is not the owner");
        require(!authorizedInstitutions[institution], "Institution is already authorized");

        authorizedInstitutions[institution] = true;

        emit InstitutionAdded(institution);
    }

    function addService(address institution, string memory service) public onlyAuthorizedInstitution {
        require(authorizedInstitutions[institution], "Institution is not authorized");

        bytes32 serviceHash = keccak256(abi.encodePacked(service));
        require(!institutionServices[institution][serviceHash], "Service already exists for this institution");

        institutionServices[institution][serviceHash] = true;

        emit ServiceAdded(institution, service);
    }

    function issueDelegation(address from, address to, address institution, string memory service) public onlyAuthorizedUser {
        // Verify that the institution is an authorized institution
        bool isAuthorizedInstitution = authorizedInstitutions[institution];
        require(isAuthorizedInstitution, "Institution is not authorized");

        // Hash the service string to convert it to bytes32
        bytes32 hashedService = hash(service);

        // Check if the hashed service exists in the institutionServices mapping for the given institution
        bool serviceExists = institutionServices[institution][hashedService];
        require(serviceExists, "Service is not valid for the given institution");

        // Add the delegation to the users mapping under the from address
        users[from][to].services[hashedService].isDelegated[to] = true;
        users[from][to].services[hashedService].delegatedAddresses.push(to);

        // Emit the DelegationIssued event
        emit DelegationIssued(from, to, institution, service);
    }

    function revokeDelegation(address from, address to, address institution, string memory service) public onlyAuthorizedUser {
        // Verify that the service is valid for the given institution
        bytes32 serviceHash = hash(service);
        bool isServiceValid = institutionServices[institution][serviceHash];
        require(isServiceValid, "Service is not valid for the given institution");

        // Check if the delegation exists in the users mapping
        Institution storage institutionDelegations = users[from][to];
        bool delegationExists = institutionDelegations.services[serviceHash].isDelegated[to];
        require(delegationExists, "Delegation does not exist");

        // Remove the delegation
        institutionDelegations.services[serviceHash].isDelegated[to] = false;

        // Emit the DelegationRevoked event
        emit DelegationRevoked(from, to, institution, service);
    }

    function checkDelegation(address from, address to, address institution, string memory service) public view returns (bool) {
        bytes32 serviceHash = hash(service);

        bool serviceExists = institutionServices[institution][serviceHash];
        if (!serviceExists) {
            return false;
        }

        Institution storage institutionDelegations = users[from][to];
        bool delegationExists = institutionDelegations.services[serviceHash].isDelegated[to];

        return delegationExists;
    }

    function getUserDelegations(address user, address institution) public view returns (bytes32[] memory) {
        // Check if the institution is authorized
        bool isAuthorized = authorizedInstitutions[institution];
        require(isAuthorized, "Institution is not authorized");

        // Retrieve the list of services for which the user has issued delegations to the institution
        Institution storage userInstitution = users[user][institution];
        uint serviceCount = userInstitution.allServices.length;
        bytes32[] memory services = new bytes32[](serviceCount);

        for (uint i = 0; i < serviceCount; i = i + 1) {
            services[i] = userInstitution.allServices[i];
        }

        return services;
    }

    function getInstitutionDelegations(address user, address institution) public view onlyAuthorizedInstitution returns (returnValue[] memory) {
        require(user != address(0), "Invalid user address");
        require(institution != address(0), "Invalid institution address");

        Institution storage userInstitution = users[user][institution];
        uint256 serviceCount = userInstitution.allServices.length;

        returnValue[] memory services = new returnValue[](serviceCount);
        for (uint256 i = 0; i < serviceCount; i = i + 1) {
            bytes32 serviceHash = userInstitution.allServices[i];
            services[i] = returnValue({
                delegated: userInstitution.services[serviceHash].delegatedAddresses[0], // Assuming one delegated address for simplicity
                services: serviceHash
            });
        }

        return services;
    }

    function isValidService(address institution, string memory service) public view returns (bool) {
        // Check if the institution is authorized
        bool isAuthorized = authorizedInstitutions[institution];
        if (!isAuthorized) {
            return false;
        }

        // Convert the service string to a bytes32 hash
        bytes32 serviceHash = keccak256(abi.encodePacked(service));

        // Check if the hashed service exists in the institutionServices mapping for the given institution
        bool serviceExists = institutionServices[institution][serviceHash];
        return serviceExists;
    }

    function isAuthorizedUser(address user) public view returns (bool) {
        require(msg.sender == owner, "Caller is not the owner");
        return authorizedUsers[user];
    }

    function isAuthorizedInstitution(address institution) public view returns (bool) {
        require(msg.sender == owner, "Caller is not the owner");
        bool isAuthorized = authorizedInstitutions[institution];
        return isAuthorized;
    }
}