pragma solidity >=0.4.22 <0.9.0;

import "./hardhat/DelegationStorage3.sol";

contract DelegationManager is DelegationStorage3 {
    // Events
    event UserAdded(address user);
    event InstitutionAdded(address institution);
    event ServiceAdded(address institution, string service);
    event DelegationIssued(address from, address to, address institution, string service);
    event DelegationRevoked(address from, address to, address institution, string service);

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
        bool isAuthorized = authorizedInstitutions[institution];
        require(!isAuthorized, "Institution is already authorized");

        authorizedInstitutions[institution] = true;

        emit InstitutionAdded(institution);
    }

    function addService(address institution, string memory service) public onlyAuthorizedInstitution {
        // Verify that the institution is authorized
        require(authorizedInstitutions[institution], "Institution is not authorized");

        // Convert the service string to a bytes32 hash
        bytes32 serviceHash = keccak256(abi.encodePacked(service));

        // Check if the service already exists for the institution
        require(!institutionServices[institution][serviceHash], "Service already exists for this institution");

        // Add the service to the institutionServices mapping
        institutionServices[institution][serviceHash] = true;

        // Emit the ServiceAdded event
        emit ServiceAdded(institution, service);
    }

    function issueDelegation(address to, address institution, string memory service) public onlyAuthorizedUser {
        // Check if the institution is authorized
        require(authorizedInstitutions[institution], "Institution is not authorized");

        // Convert the service string to a bytes32 hash
        bytes32 serviceHash = keccak256(abi.encodePacked(service));

        // Verify if the service is valid for the given institution
        require(institutionServices[institution][serviceHash], "Service is not valid for the given institution");

        // Record the delegation in the users mapping
        users[msg.sender][institution].services[serviceHash].isDelegated[to] = true;

        // Emit the DelegationIssued event
        emit DelegationIssued(msg.sender, to, institution, service);
    }

    function revokeDelegation(address to, address institution, string memory service) public onlyAuthorizedUser {
        // Verify that the service is valid for the given institution
        bytes32 serviceHash = keccak256(abi.encodePacked(service));
        bool isServiceValid = institutionServices[institution][serviceHash];
        require(isServiceValid, "Service is not valid for the given institution");

        // Check if the delegation exists
        Institution storage institutionDelegations = users[msg.sender][institution];
        bool delegationExists = institutionDelegations.services[serviceHash].isDelegated[to];
        require(delegationExists, "Delegation does not exist");

        // Remove the delegation
        institutionDelegations.services[serviceHash].isDelegated[to] = false;

        // Emit the DelegationRevoked event
        emit DelegationRevoked(msg.sender, to, institution, service);
    }

    function checkDelegation(address delegated, address institution, string memory service) public view onlyAuthorizedUser returns (bool) {
        // Ensure the institution is authorized
        bool isAuthorizedInstitution = authorizedInstitutions[institution];
        require(isAuthorizedInstitution, "Institution is not authorized");

        // Convert the service string to a bytes32 hash
        bytes32 serviceHash = keccak256(abi.encodePacked(service));

        // Check if the service exists for the institution
        bool serviceExists = institutionServices[institution][serviceHash];
        require(serviceExists, "Service is not valid for the given institution");

        // Verify if the delegation exists
        Institution storage institutionDelegations = users[delegated][institution];
        bool delegationExists = institutionDelegations.services[serviceHash].isDelegated[delegated];

        return delegationExists;
    }

    function getUserDelegations(address user, address institution) public view onlyAuthorizedUser returns (address[] memory, string[] memory) {
        // Check if the institution is valid and has services
        require(authorizedInstitutions[institution], "Institution is not authorized");

        // Initialize dynamic arrays to store the results
        address[] memory delegatedUsers = new address[](0);
        string[] memory serviceNames = new string[](0);

        // Get the institution's services
        mapping(bytes32 => bool) storage services = institutionServices[institution];

        // Get the delegation details
        Institution storage institutionDelegations = users[user][institution];

        // Iterate through the services of the institution
        for (uint256 i = 0; i < institutionDelegations.allServices.length; i++) {
            bytes32 serviceHash = institutionDelegations.allServices[i];
            if (institutionDelegations.services[serviceHash].isDelegated[user]) {
                // Resize the arrays to accommodate the new entry
                address[] memory newDelegatedUsers = new address[](delegatedUsers.length + 1);
                string[] memory newServiceNames = new string[](serviceNames.length + 1);

                for (uint256 j = 0; j < delegatedUsers.length; j++) {
                    newDelegatedUsers[j] = delegatedUsers[j];
                    newServiceNames[j] = serviceNames[j];
                }

                newDelegatedUsers[delegatedUsers.length] = user;
                newServiceNames[serviceNames.length] = string(abi.encodePacked(serviceHash));

                delegatedUsers = newDelegatedUsers;
                serviceNames = newServiceNames;
            }
        }

        return (delegatedUsers, serviceNames);
    }

    function getInstitutionDelegations(address user, address institution) public view onlyAuthorizedInstitution returns (address[] memory, string[] memory) {
        require(authorizedInstitutions[institution], "Institution is not authorized");

        // Retrieve the delegations for the specified user and institution
        Institution storage inst = users[user][institution];

        // Initialize dynamic arrays to store results
        address[] memory delegatedUsers = new address[](inst.allServices.length);
        string[] memory services = new string[](inst.allServices.length);

        // Iterate through the services of the institution
        uint256 serviceCount = 0;
        for (uint256 i = 0; i < inst.allServices.length; i++) {
            bytes32 serviceHash = inst.allServices[i];
            if (inst.services[serviceHash].isDelegated[user]) {
                // Add the delegated user and service name to the result arrays
                delegatedUsers[serviceCount] = user;
                services[serviceCount] = string(abi.encodePacked(serviceHash));
                serviceCount++;
            }
        }

        // Resize the arrays to the actual number of delegations
        assembly {
            mstore(delegatedUsers, serviceCount)
            mstore(services, serviceCount)
        }

        // Return the arrays containing the delegated users and service names
        return (delegatedUsers, services);
    }

    function isValidService(address institution, string memory service) public view returns (bool) {
        if (!authorizedInstitutions[institution]) {
            return false;
        }

        bytes32 serviceHash = keccak256(abi.encodePacked(service));
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