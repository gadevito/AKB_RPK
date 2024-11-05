// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./hardhat/interfaces/LinkTokenInterface.sol";
import "./hardhat/vendor/SafeMathChainlink.sol";
import "./hardhat/VRFRequestIDBase.sol";
import "./hardhat/VRFConsumerBase.sol";

contract DelegationManager is VRFConsumerBase {
    using SafeMathChainlink for uint256;

    address public owner;
    mapping(address => bool) public authorizedUsers;
    mapping(address => bool) public authorizedInstitutions;
    mapping(address => mapping(address => mapping(string => address))) public delegations; // user => institution => service => delegated
    mapping(address => mapping(address => string[])) public userDelegations; // user => institution => services
    mapping(address => string[]) public institutionServices; // institution => services

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyAuthorizedUser() {
        require(authorizedUsers[msg.sender], "Only authorized users can perform this action");
        _;
    }

    modifier onlyAuthorizedInstitution() {
        require(authorizedInstitutions[msg.sender], "Only authorized institutions can perform this action");
        _;
    }

    constructor(address _vrfCoordinator, address _link) VRFConsumerBase(_vrfCoordinator, _link) {
        owner = msg.sender;
    }

    function addUser(address user) external onlyOwner {
        authorizedUsers[user] = true;
    }

    function addInstitution(address institution) external onlyOwner {
        authorizedInstitutions[institution] = true;
    }

    function addService(address institution, string calldata service) external onlyAuthorizedInstitution {
        require(authorizedInstitutions[institution], "Institution not authorized");
        institutionServices[institution].push(service);
    }

    function issueDelegation(address institution, string calldata service, address delegated) external onlyAuthorizedUser {
        require(authorizedInstitutions[institution], "Institution not authorized");
        require(isValidService(institution, service), "Service not valid for institution");
        delegations[msg.sender][institution][service] = delegated;
        userDelegations[msg.sender][institution].push(service);
    }

    function revokeDelegation(address institution, string calldata service) external onlyAuthorizedUser {
        require(delegations[msg.sender][institution][service] != address(0), "Delegation does not exist");
        delete delegations[msg.sender][institution][service];
        // Remove service from userDelegations
        string[] storage services = userDelegations[msg.sender][institution];
        for (uint256 i = 0; i < services.length; i++) {
            if (keccak256(bytes(services[i])) == keccak256(bytes(service))) {
                services[i] = services[services.length - 1];
                services.pop();
                break;
            }
        }
    }

    function checkDelegation(address user, address institution, string calldata service) external view returns (address) {
        return delegations[user][institution][service];
    }

    function getUserDelegations(address institution) external view onlyAuthorizedUser returns (string[] memory) {
        return userDelegations[msg.sender][institution];
    }

    function getInstitutionDelegations(address user) external view onlyAuthorizedInstitution returns (string[] memory) {
        return userDelegations[user][msg.sender];
    }

    function isValidService(address institution, string calldata service) public view returns (bool) {
        string[] storage services = institutionServices[institution];
        for (uint256 i = 0; i < services.length; i++) {
            if (keccak256(bytes(services[i])) == keccak256(bytes(service))) {
                return true;
            }
        }
        return false;
    }

    function isAuthorizedUser(address user) external view returns (bool) {
        return authorizedUsers[user];
    }

    function isAuthorizedInstitution(address institution) external view returns (bool) {
        return authorizedInstitutions[institution];
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // Implement your logic here if needed
    }
}