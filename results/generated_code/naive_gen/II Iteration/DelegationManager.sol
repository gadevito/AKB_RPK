// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./hardhat/interfaces/LinkTokenInterface.sol";
import "./hardhat/vendor/SafeMathChainlink.sol";
import "./hardhat/VRFRequestIDBase.sol";
import "./hardhat/VRFConsumerBase.sol";

contract DelegationManager is VRFConsumerBase {
    using SafeMathChainlink for uint256;

    address public owner;
    LinkTokenInterface private linkToken;

    struct Service {
        string name;
        bool exists;
    }

    struct Institution {
        string name;
        bool exists;
        mapping(string => Service) services;
        string[] serviceList;
    }

    struct Delegation {
        address from;
        address to;
        string service;
        bool exists;
    }

    mapping(address => bool) public authorizedUsers;
    mapping(address => Institution) public authorizedInstitutions;
    mapping(address => mapping(address => mapping(string => Delegation))) public delegations;
    mapping(address => mapping(address => string[])) public userDelegations;
    mapping(address => mapping(string => address[])) public institutionDelegations;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyAuthorizedUser() {
        require(authorizedUsers[msg.sender], "Only authorized users can perform this action");
        _;
    }

    modifier onlyAuthorizedInstitution() {
        require(authorizedInstitutions[msg.sender].exists, "Only authorized institutions can perform this action");
        _;
    }

    constructor(address _vrfCoordinator, address _link) VRFConsumerBase(_vrfCoordinator, _link) {
        owner = msg.sender;
        linkToken = LinkTokenInterface(_link);
    }

    function addUser(address user) external onlyOwner {
        authorizedUsers[user] = true;
    }

    function addInstitution(address institution, string memory name) external onlyOwner {
        authorizedInstitutions[institution].name = name;
        authorizedInstitutions[institution].exists = true;
    }

    function addService(address institution, string memory serviceName) external onlyAuthorizedInstitution {
        require(authorizedInstitutions[institution].exists, "Institution not authorized");
        authorizedInstitutions[institution].services[serviceName] = Service(serviceName, true);
        authorizedInstitutions[institution].serviceList.push(serviceName);
    }

    function issueDelegation(address to, address institution, string memory service) external onlyAuthorizedUser {
        require(authorizedUsers[to], "Recipient not authorized");
        require(authorizedInstitutions[institution].services[service].exists, "Service not authorized");

        delegations[msg.sender][to][service] = Delegation(msg.sender, to, service, true);
        userDelegations[msg.sender][institution].push(service);
        institutionDelegations[institution][service].push(to);
    }

    function revokeDelegation(address to, address institution, string memory service) external onlyAuthorizedUser {
        require(delegations[msg.sender][to][service].exists, "Delegation does not exist");

        delete delegations[msg.sender][to][service];

        // Remove from userDelegations
        string[] storage userServices = userDelegations[msg.sender][institution];
        for (uint256 i = 0; i < userServices.length; i++) {
            if (keccak256(abi.encodePacked(userServices[i])) == keccak256(abi.encodePacked(service))) {
                userServices[i] = userServices[userServices.length - 1];
                userServices.pop();
                break;
            }
        }

        // Remove from institutionDelegations
        address[] storage institutionUsers = institutionDelegations[institution][service];
        for (uint256 i = 0; i < institutionUsers.length; i++) {
            if (institutionUsers[i] == to) {
                institutionUsers[i] = institutionUsers[institutionUsers.length - 1];
                institutionUsers.pop();
                break;
            }
        }
    }

    function checkDelegation(address from, address to, address institution, string memory service) external view returns (bool) {
        return delegations[from][to][service].exists;
    }

    function getUserDelegations(address user, address institution) external view returns (string[] memory) {
        return userDelegations[user][institution];
    }

    function getInstitutionDelegations(address institution, address user) external view returns (string[] memory) {
        return userDelegations[user][institution];
    }

    function isValidService(address institution, string memory service) external view returns (bool) {
        return authorizedInstitutions[institution].services[service].exists;
    }

    function isAuthorizedUser(address user) external view returns (bool) {
        return authorizedUsers[user];
    }

    function isAuthorizedInstitution(address institution) external view returns (bool) {
        return authorizedInstitutions[institution].exists;
    }

    // Implement the fulfillRandomness function as required by VRFConsumerBase
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // Implement your logic here
    }
}