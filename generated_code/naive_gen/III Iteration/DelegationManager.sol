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
    mapping(address => mapping(address => mapping(string => address))) public delegations;
    mapping(address => mapping(address => string[])) public userDelegations;
    mapping(address => string[]) public institutionServices;

    event UserAdded(address user);
    event InstitutionAdded(address institution);
    event ServiceAdded(address institution, string service);
    event DelegationIssued(address from, address to, address institution, string service);
    event DelegationRevoked(address from, address to, address institution, string service);

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
        emit UserAdded(user);
    }

    function addInstitution(address institution) external onlyOwner {
        authorizedInstitutions[institution] = true;
        emit InstitutionAdded(institution);
    }

    function addService(address institution, string calldata service) external onlyAuthorizedInstitution {
        require(authorizedInstitutions[institution], "Institution not authorized");
        institutionServices[institution].push(service);
        emit ServiceAdded(institution, service);
    }

    function issueDelegation(address to, address institution, string calldata service) external onlyAuthorizedUser {
        require(authorizedUsers[to], "Recipient not authorized");
        require(isValidService(institution, service), "Invalid service for institution");
        delegations[msg.sender][institution][service] = to;
        userDelegations[msg.sender][institution].push(service);
        emit DelegationIssued(msg.sender, to, institution, service);
    }

    function revokeDelegation(address to, address institution, string calldata service) external onlyAuthorizedUser {
        require(delegations[msg.sender][institution][service] == to, "Delegation not found");
        delete delegations[msg.sender][institution][service];
        emit DelegationRevoked(msg.sender, to, institution, service);
    }

    function checkDelegation(address from, address institution, string calldata service) external view returns (address) {
        return delegations[from][institution][service];
    }

    function getUserDelegations(address user, address institution) external view returns (string[] memory) {
        return userDelegations[user][institution];
    }

    function getInstitutionDelegations(address institution, address user) external view returns (string[] memory) {
        return userDelegations[user][institution];
    }

    function isValidService(address institution, string calldata service) public view returns (bool) {
        string[] memory services = institutionServices[institution];
        for (uint256 i = 0; i < services.length; i++) {
            if (keccak256(abi.encodePacked(services[i])) == keccak256(abi.encodePacked(service))) {
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

    // Implement the fulfillRandomness function as required by VRFConsumerBase
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        // Implement your logic here
    }
}