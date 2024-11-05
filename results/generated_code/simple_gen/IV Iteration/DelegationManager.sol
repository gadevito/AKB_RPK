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

    function hash(string memory serviceName) internal pure override returns (bytes32) {
        return keccak256(abi.encodePacked(serviceName));
    }

    function addUser(address user) external onlyOwner {
        authorizedUsers[user] = true;
    }

    function addInstitution(address institution) external onlyOwner {
        authorizedInstitutions[institution] = true;
    }

    function isAuthorizedUser(address user) external view returns (bool) {
        return authorizedUsers[user];
    }

    function isAuthorizedInstitution(address institution) external view returns (bool) {
        return authorizedInstitutions[institution];
    }

    function addService(address institution, string memory serviceName) external onlyAuthorizedInstitution {
        bytes32 serviceHash = hash(serviceName);
        require(!institutionServices[institution][serviceHash], "Service already exists");
        institutionServices[institution][serviceHash] = true;
    }

    function issueDelegation(address to, address institution, string memory serviceName, uint256 amount) external onlyAuthorizedUser {
        bytes32 serviceHash = hash(serviceName);
        require(institutionServices[institution][serviceHash], "Service does not exist");
        require(authorizedUsers[to], "Delegated user is not authorized");

        Institution storage inst = users[msg.sender][institution];
        Service storage service = inst.services[serviceHash];

        if (!inst.servicePresent[serviceHash]) {
            inst.allServices.push(serviceHash);
            inst.servicePresent[serviceHash] = true;
        }

        if (!service.isDelegated[to]) {
            service.delegatedAddresses.push(to);
            service.isDelegated[to] = true;
        } else {
            service.delegationAmount += amount;
        }
    }

    function revokeDelegation(address to, address institution, string memory serviceName) external onlyAuthorizedUser {
        bytes32 serviceHash = hash(serviceName);
        require(institutionServices[institution][serviceHash], "Service does not exist");

        Institution storage inst = users[msg.sender][institution];
        Service storage service = inst.services[serviceHash];

        require(service.isDelegated[to], "Delegation does not exist");

        service.isDelegated[to] = false;
        service.delegationAmount = 0;

        for (uint i = 0; i < service.delegatedAddresses.length; i++) {
            if (service.delegatedAddresses[i] == to) {
                service.delegatedAddresses[i] = service.delegatedAddresses[service.delegatedAddresses.length - 1];
                service.delegatedAddresses.pop();
                break;
            }
        }
    }

    function checkDelegation(address from, address institution, string memory serviceName) external view returns (bool, uint256) {
        bytes32 serviceHash = hash(serviceName);
        if (!institutionServices[institution][serviceHash]) {
            return (false, 0);
        }

        Institution storage inst = users[from][institution];
        Service storage service = inst.services[serviceHash];

        if (!service.isDelegated[msg.sender]) {
            return (false, 0);
        }

        return (true, service.delegationAmount);
    }

    function getUserDelegations(address institution) external view onlyAuthorizedUser returns (returnValue[] memory) {
        Institution storage inst = users[msg.sender][institution];
        uint totalServices = inst.allServices.length;
        uint totalDelegations = 0;

        for (uint i = 0; i < totalServices; i++) {
            Service storage service = inst.services[inst.allServices[i]];
            totalDelegations += service.delegatedAddresses.length;
        }

        returnValue[] memory delegations = new returnValue[](totalDelegations);
        uint index = 0;

        for (uint i = 0; i < totalServices; i++) {
            Service storage service = inst.services[inst.allServices[i]];
            for (uint j = 0; j < service.delegatedAddresses.length; j++) {
                delegations[index] = returnValue(service.delegatedAddresses[j], inst.allServices[i]);
                index++;
            }
        }

        return delegations;
    }

    function getInstitutionDelegations(address user) external view onlyAuthorizedInstitution returns (returnValue[] memory) {
        Institution storage inst = users[user][msg.sender];
        uint totalServices = inst.allServices.length;
        uint totalDelegations = 0;

        for (uint i = 0; i < totalServices; i++) {
            Service storage service = inst.services[inst.allServices[i]];
            totalDelegations += service.delegatedAddresses.length;
        }

        returnValue[] memory delegations = new returnValue[](totalDelegations);
        uint index = 0;

        for (uint i = 0; i < totalServices; i++) {
            Service storage service = inst.services[inst.allServices[i]];
            for (uint j = 0; j < service.delegatedAddresses.length; j++) {
                delegations[index] = returnValue(service.delegatedAddresses[j], inst.allServices[i]);
                index++;
            }
        }

        return delegations;
    }

    function isValidService(address institution, string memory serviceName) external view returns (bool) {
        bytes32 serviceHash = hash(serviceName);
        return institutionServices[institution][serviceHash];
    }
}