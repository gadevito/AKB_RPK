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
        require(authorizedInstitutions[institution], "Institution must be authorized");
        bytes32 serviceHash = hash(service);
        require(institutionServices[institution][serviceHash], "Service must be valid");

        users[msg.sender][institution].services[serviceHash].isDelegated[to] = true;
        users[msg.sender][institution].services[serviceHash].delegatedAddresses.push(to);
        users[msg.sender][institution].services[serviceHash].delegationAmount = amount;
    }

    function revokeDelegation(address to, address institution, string memory service) external onlyAuthorizedUser {
        bytes32 serviceHash = hash(service);
        require(users[msg.sender][institution].services[serviceHash].isDelegated[to], "Delegation does not exist");

        users[msg.sender][institution].services[serviceHash].isDelegated[to] = false;
    }

    function checkDelegation(address from, address to, address institution, string memory service) external view returns (bool) {
        bytes32 serviceHash = hash(service);
        return users[from][institution].services[serviceHash].isDelegated[to];
    }

    function getDelegationsForInstitution(address institution) external view onlyAuthorizedUser returns (returnValue[] memory) {
        Institution storage inst = users[msg.sender][institution];
        uint256 totalServices = inst.allServices.length;
        uint256 count = 0;

        for (uint256 i = 0; i < totalServices; i++) {
            bytes32 serviceHash = inst.allServices[i];
            Service storage service = inst.services[serviceHash];
            for (uint256 j = 0; j < service.delegatedAddresses.length; j++) {
                if (service.isDelegated[service.delegatedAddresses[j]]) {
                    count++;
                }
            }
        }

        returnValue[] memory result = new returnValue[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < totalServices; i++) {
            bytes32 serviceHash = inst.allServices[i];
            Service storage service = inst.services[serviceHash];
            for (uint256 j = 0; j < service.delegatedAddresses.length; j++) {
                if (service.isDelegated[service.delegatedAddresses[j]]) {
                    result[index] = returnValue(service.delegatedAddresses[j], serviceHash);
                    index++;
                }
            }
        }
        return result;
    }

    function getDelegationsFromUser(address user) external view onlyAuthorizedInstitution returns (returnValue[] memory) {
        Institution storage inst = users[user][msg.sender];
        uint256 totalServices = inst.allServices.length;
        uint256 count = 0;

        for (uint256 i = 0; i < totalServices; i++) {
            bytes32 serviceHash = inst.allServices[i];
            Service storage service = inst.services[serviceHash];
            for (uint256 j = 0; j < service.delegatedAddresses.length; j++) {
                if (service.isDelegated[service.delegatedAddresses[j]]) {
                    count++;
                }
            }
        }

        returnValue[] memory result = new returnValue[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < totalServices; i++) {
            bytes32 serviceHash = inst.allServices[i];
            Service storage service = inst.services[serviceHash];
            for (uint256 j = 0; j < service.delegatedAddresses.length; j++) {
                if (service.isDelegated[service.delegatedAddresses[j]]) {
                    result[index] = returnValue(service.delegatedAddresses[j], serviceHash);
                    index++;
                }
            }
        }
        return result;
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