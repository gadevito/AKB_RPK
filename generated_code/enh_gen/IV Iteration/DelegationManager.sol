pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./hardhat/DelegationStorage3.sol";

contract DelegationManager is DelegationStorage3 {
    // Local Variables
    mapping(address => mapping(address => mapping(address => mapping(bytes32 => bool)))) public delegations;

    // Events
    event UserAdded(address indexed user);
    event InstitutionAdded(address indexed institution);
    event ServiceAdded(address indexed institution, string service);
    event DelegationIssued(address indexed from, address indexed to, address indexed institution, string service);
    event DelegationRevoked(address indexed from, address indexed to, address indexed institution, string service);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyAuthorizedUser() {
        require(authorizedUsers[msg.sender], "Only an authorized user can call this function");
        _;
    }

    modifier onlyAuthorizedInstitution() {
        require(authorizedInstitutions[msg.sender], "Only an authorized institution can call this function");
        _;
    }

    // Constructor
    constructor() public {
        // Default constructor logic if any
    }

function addUser(address user) public onlyOwner {
    bool isAuthorized = authorizedUsers[user];
    require(!isAuthorized, "User is already authorized");

    authorizedUsers[user] = true;

    emit UserAdded(user);
}


function addInstitution(address institution) public onlyOwner {
    bool isAuthorized = authorizedInstitutions[institution];
    require(!isAuthorized, "Institution is already authorized");

    authorizedInstitutions[institution] = true;

    emit InstitutionAdded(institution);
}


function addService(address institution, string memory service) public onlyAuthorizedInstitution {
    // Ensure the institution is authorized
    require(authorizedInstitutions[institution], "Institution is not authorized");

    // Convert the service string to bytes32 format
    bytes32 serviceHash = hash(service);

    // Check if the service already exists for the institution
    require(!institutionServices[institution][serviceHash], "Service already exists for this institution");

    // Add the hashed service to the institutionServices mapping
    institutionServices[institution][serviceHash] = true;

    // Emit the ServiceAdded event
    emit ServiceAdded(institution, service);
}


function issueDelegation(address to, address institution, string memory service) public onlyAuthorizedUser {
    // Check if the institution is authorized
    bool isAuthorizedInstitution = authorizedInstitutions[institution];
    require(isAuthorizedInstitution, "Institution is not authorized");

    // Convert the service string to bytes32
    bytes32 serviceHash = hash(service);

    // Check if the service is valid for the given institution
    bool isValidService = institutionServices[institution][serviceHash];
    require(isValidService, "Service is not valid for the given institution");

    // Update the delegations mapping to record the delegation
    delegations[msg.sender][to][institution][serviceHash] = true;

    // Emit the DelegationIssued event
    emit DelegationIssued(msg.sender, to, institution, service);
}


function revokeDelegation(address to, address institution, string memory service) public onlyAuthorizedUser {
    // Hash the service string to bytes32
    bytes32 hashedService = hash(service);

    // Check if the delegation exists
    bool delegationExists = delegations[msg.sender][to][institution][hashedService];
    require(delegationExists, "Delegation does not exist");

    // Revoke the delegation
    delegations[msg.sender][to][institution][hashedService] = false;

    // Emit the DelegationRevoked event
    emit DelegationRevoked(msg.sender, to, institution, service);
}


function checkDelegation(address delegated, address institution, string memory service) public view returns (bool) {
    bytes32 serviceHash = hash(service);
    bool delegationExists = delegations[msg.sender][delegated][institution][serviceHash];
    return delegationExists;
}


function getUserDelegations(address user, address institution) public view onlyAuthorizedUser returns (bytes32[] memory) {
    // Initialize a dynamic array to store the service hashes
    bytes32[] memory serviceHashes = new bytes32[](0);

    // Get the delegations for the user and institution
    mapping(address => mapping(bytes32 => bool)) storage userDelegations = delegations[user][institution];

    // Count the number of services delegated
    uint256 count = 0;
    for (uint256 i = 0; i < serviceHashes.length; i = i + 1) {
        if (userDelegations[institution][serviceHashes[i]]) {
            count = count + 1;
        }
    }

    // Create an array to store the valid service hashes
    bytes32[] memory validServiceHashes = new bytes32[](count);
    uint256 index = 0;
    for (uint256 i = 0; i < serviceHashes.length; i = i + 1) {
        if (userDelegations[institution][serviceHashes[i]]) {
            validServiceHashes[index] = serviceHashes[i];
            index = index + 1;
        }
    }

    return validServiceHashes;
}


function getInstitutionDelegations(address user, address institution) public view onlyAuthorizedInstitution returns (bytes32[] memory) {
    // Initialize a dynamic array to store the services
    bytes32[] memory services = new bytes32[](0);

    // Get the delegations for the user and institution
    mapping(address => mapping(bytes32 => bool)) storage userDelegations = delegations[user][institution];

    // Count the number of services
    uint256 serviceCount = 0;
    for (uint256 i = 0; i < services.length; i = i + 1) {
        bytes32 service = services[i];
        if (userDelegations[institution][service]) {
            serviceCount = serviceCount + 1;
        }
    }

    // Create an array to store the valid services
    bytes32[] memory validServices = new bytes32[](serviceCount);
    uint256 index = 0;
    for (uint256 i = 0; i < services.length; i = i + 1) {
        bytes32 service = services[i];
        if (userDelegations[institution][service]) {
            validServices[index] = service;
            index = index + 1;
        }
    }

    return validServices;
}


function isValidService(address institution, string memory service) public view returns (bool) {
    bytes32 serviceHash = hash(service);
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