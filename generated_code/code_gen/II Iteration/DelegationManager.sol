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
    constructor() public {
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
        // Hash the service name
        bytes32 serviceHash = keccak256(abi.encodePacked(service));

        // Check if the service already exists for the institution
        bool serviceExists = institutionServices[institution][serviceHash];
        require(!serviceExists, "Service already exists for this institution");

        // Add the service to the institutionServices mapping
        institutionServices[institution][serviceHash] = true;

        // Emit the ServiceAdded event
        emit ServiceAdded(institution, service);
    }

    function issueDelegation(address to, address institution, string memory service) public onlyAuthorizedUser {
        // Check if the institution is authorized
        require(authorizedInstitutions[institution], "Institution is not authorized");

        // Hash the service
        bytes32 hashedService = keccak256(abi.encodePacked(service));

        // Check if the service is valid
        require(institutionServices[institution][hashedService], "Service is not valid for the institution");

        // Issue the delegation
        users[msg.sender][institution].services[hashedService].isDelegated[to] = true;

        // Emit the DelegationIssued event
        emit DelegationIssued(msg.sender, to, institution, service);
    }

    function revokeDelegation(address _to, address _institution, string memory _service) public onlyAuthorizedUser {
        // Hash the service
        bytes32 hashedService = keccak256(abi.encodePacked(_service));

        // Check if the service is valid
        bool serviceExists = institutionServices[_institution][hashedService];
        require(serviceExists, "Service not valid for the given institution");

        // Check if the delegation exists
        bool delegationExists = users[msg.sender][_institution].services[hashedService].isDelegated[_to];
        require(delegationExists, "Delegation not found");

        // Revoke the delegation
        users[msg.sender][_institution].services[hashedService].isDelegated[_to] = false;

        // Emit the DelegationRevoked event
        emit DelegationRevoked(msg.sender, _to, _institution, _service);
    }

    function checkDelegation(address _delegated, address _institution, string memory _service) public view returns (bool) {
        // Hash the service string
        bytes32 hashedService = keccak256(abi.encodePacked(_service));

        // Check if the service exists for the given institution
        bool serviceExists = institutionServices[_institution][hashedService];
        if (!serviceExists) {
            return false;
        }

        // Check if the delegation exists
        bool delegationExists = users[_delegated][_institution].services[hashedService].isDelegated[_delegated];

        return delegationExists;
    }

    function getUserDelegations(address user, address institution) public view onlyAuthorizedUser returns (string[] memory) {
        // Ensure the user and institution addresses are valid
        require(user != address(0), "Invalid user address");
        require(institution != address(0), "Invalid institution address");

        // Retrieve the delegations for the specified user and institution
        Institution storage userInstitution = users[user][institution];

        // Initialize an array to store the service names
        string[] memory services = new string[](userInstitution.allServices.length);

        // Populate the services array
        for (uint i = 0; i < userInstitution.allServices.length; i = i + 1) {
            services[i] = string(abi.encodePacked(userInstitution.allServices[i]));
        }

        // Return the list of services
        return services;
    }

    function getInstitutionDelegations(address user) public view onlyAuthorizedInstitution returns (bytes32[] memory) {
        // Ensure the caller is an authorized institution
        require(authorizedInstitutions[msg.sender], "Caller is not an authorized institution");

        // Retrieve the delegations for the specified user and calling institution
        Institution storage institution = users[user][msg.sender];
        uint serviceCount = institution.allServices.length;

        // Create an array to hold the service hashes
        bytes32[] memory services = new bytes32[](serviceCount);

        // Populate the services array
        for (uint i = 0; i < serviceCount; i = i + 1) {
            services[i] = institution.allServices[i];
        }

        return services;
    }

    function isValidService(address institution, string memory service) public view returns (bool) {
        bytes32 serviceHash = keccak256(abi.encodePacked(service));
        bool serviceExists = institutionServices[institution][serviceHash];
        return serviceExists;
    }

    function isAuthorizedUser(address user) public view returns (bool) {
        bool isAuthorized = authorizedUsers[user];
        return isAuthorized;
    }

    function isAuthorizedInstitution(address institution) public view returns (bool) {
        bool isAuthorized = authorizedInstitutions[institution];
        return isAuthorized;
    }
}