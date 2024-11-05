// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import './hardhat/DelegationStorage3.sol';

contract DelegationManager is DelegationStorage3 {

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

    function addUser(address user) external onlyOwner {
        authorizedUsers[user] = true;
    }

    function addInstitution(address institution) external onlyOwner {
        authorizedInstitutions[institution] = true;
    }

    function addService(address institution, string memory service) external onlyAuthorizedInstitution {
        bytes32 serviceHash = hash(service);
        require(!institutionServices[institution][serviceHash], "Service already exists");
        institutionServices[institution][serviceHash] = true;
    }

    function issueDelegation(address to, address institution, string memory service, uint256 amount) external onlyAuthorizedUser {
        require(authorizedUsers[to], "Delegated user must be authorized");
        bytes32 serviceHash = hash(service);
        require(institutionServices[institution][serviceHash], "Service does not exist");

        users[msg.sender][to].services[serviceHash].isDelegated[to] = true;
        users[msg.sender][to].services[serviceHash].delegatedAddresses.push(to);
        users[msg.sender][to].services[serviceHash].delegationAmount = amount;

        if (!users[msg.sender][to].servicePresent[serviceHash]) {
            users[msg.sender][to].allServices.push(serviceHash);
            users[msg.sender][to].servicePresent[serviceHash] = true;
        }
    }

    function revokeDelegation(address to, address institution, string memory service) external onlyAuthorizedUser {
        bytes32 serviceHash = hash(service);
        require(users[msg.sender][to].services[serviceHash].isDelegated[to], "Delegation does not exist");

        users[msg.sender][to].services[serviceHash].isDelegated[to] = false;
        users[msg.sender][to].services[serviceHash].delegationAmount = 0;
    }

    function checkDelegation(address from, address to, address institution, string memory service) external view returns (bool, uint256) {
        bytes32 serviceHash = hash(service);
        return (
            users[from][to].services[serviceHash].isDelegated[to],
            users[from][to].services[serviceHash].delegationAmount
        );
    }

    function getUserDelegations(address institution) external view onlyAuthorizedUser returns (returnValue[] memory) {
        Institution storage inst = users[msg.sender][institution];
        uint256 count = 0;

        for (uint i = 0; i < inst.allServices.length; i++) {
            bytes32 serviceHash = inst.allServices[i];
            if (inst.services[serviceHash].isDelegated[institution]) {
                count++;
            }
        }

        returnValue[] memory delegations = new returnValue[](count);
        uint256 index = 0;

        for (uint i = 0; i < inst.allServices.length; i++) {
            bytes32 serviceHash = inst.allServices[i];
            if (inst.services[serviceHash].isDelegated[institution]) {
                delegations[index] = returnValue({
                    delegated: institution,
                    services: serviceHash
                });
                index++;
            }
        }

        return delegations;
    }

    function getInstitutionDelegations(address user) external view onlyAuthorizedInstitution returns (returnValue[] memory) {
        Institution storage inst = users[user][msg.sender];
        uint256 count = 0;

        for (uint i = 0; i < inst.allServices.length; i++) {
            bytes32 serviceHash = inst.allServices[i];
            if (inst.services[serviceHash].isDelegated[user]) {
                count++;
            }
        }

        returnValue[] memory delegations = new returnValue[](count);
        uint256 index = 0;

        for (uint i = 0; i < inst.allServices.length; i++) {
            bytes32 serviceHash = inst.allServices[i];
            if (inst.services[serviceHash].isDelegated[user]) {
                delegations[index] = returnValue({
                    delegated: user,
                    services: serviceHash
                });
                index++;
            }
        }

        return delegations;
    }

    function isValidService(address institution, string memory service) external view returns (bool) {
        bytes32 serviceHash = hash(service);
        return institutionServices[institution][serviceHash];
    }

    function isAuthorizedUser(address user) external view onlyOwner returns (bool) {
        return authorizedUsers[user];
    }

    function isAuthorizedInstitution(address institution) external view onlyOwner returns (bool) {
        return authorizedInstitutions[institution];
    }
}