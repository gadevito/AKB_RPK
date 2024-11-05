// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import './hardhat/DelegationStorage3.sol';

contract DelegationManager is DelegationStorage3 {

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier onlyAuthorizedUser() {
        require(authorizedUsers[msg.sender], "Not an authorized user");
        _;
    }

    modifier onlyAuthorizedInstitution() {
        require(authorizedInstitutions[msg.sender], "Not an authorized institution");
        _;
    }

    function addUser(address user) public onlyOwner {
        authorizedUsers[user] = true;
    }

    function addInstitution(address institution) public onlyOwner {
        authorizedInstitutions[institution] = true;
    }

    function addService(address institution, string memory serviceName) public onlyAuthorizedInstitution {
        bytes32 serviceHash = hash(serviceName);
        require(!institutionServices[institution][serviceHash], "Service already exists");
        institutionServices[institution][serviceHash] = true;
    }

    function issueDelegation(address to, address institution, string memory serviceName, uint256 amount) public onlyAuthorizedUser {
        require(authorizedUsers[to], "Recipient is not an authorized user");
        require(authorizedInstitutions[institution], "Institution is not authorized");
        bytes32 serviceHash = hash(serviceName);
        require(institutionServices[institution][serviceHash], "Service does not exist");

        users[msg.sender][institution].services[serviceHash].isDelegated[to] = true;
        users[msg.sender][institution].services[serviceHash].delegatedAddresses.push(to);
        users[msg.sender][institution].services[serviceHash].delegationAmount = amount;

        if (!users[msg.sender][institution].servicePresent[serviceHash]) {
            users[msg.sender][institution].allServices.push(serviceHash);
            users[msg.sender][institution].servicePresent[serviceHash] = true;
        }
    }

    function revokeDelegation(address to, address institution, string memory serviceName) public onlyAuthorizedUser {
        bytes32 serviceHash = hash(serviceName);
        require(users[msg.sender][institution].services[serviceHash].isDelegated[to], "Delegation does not exist");

        users[msg.sender][institution].services[serviceHash].isDelegated[to] = false;
        address[] storage delegatedAddresses = users[msg.sender][institution].services[serviceHash].delegatedAddresses;
        for (uint i = 0; i < delegatedAddresses.length; i++) {
            if (delegatedAddresses[i] == to) {
                delegatedAddresses[i] = delegatedAddresses[delegatedAddresses.length - 1];
                delegatedAddresses.pop();
                break;
            }
        }
    }

    function checkDelegation(address from, address institution, string memory serviceName) public view returns (bool) {
        bytes32 serviceHash = hash(serviceName);
        return users[from][institution].services[serviceHash].isDelegated[msg.sender];
    }

    function getUserDelegations(address institution) public view onlyAuthorizedUser returns (returnValue[] memory) {
        bytes32[] storage services = users[msg.sender][institution].allServices;
        uint totalDelegations = 0;

        for (uint i = 0; i < services.length; i++) {
            totalDelegations += users[msg.sender][institution].services[services[i]].delegatedAddresses.length;
        }

        returnValue[] memory result = new returnValue[](totalDelegations);
        uint index = 0;

        for (uint i = 0; i < services.length; i++) {
            address[] storage delegatedAddresses = users[msg.sender][institution].services[services[i]].delegatedAddresses;
            for (uint j = 0; j < delegatedAddresses.length; j++) {
                result[index] = returnValue(delegatedAddresses[j], services[i]);
                index++;
            }
        }

        return result;
    }

    function getInstitutionDelegations(address user) public view onlyAuthorizedInstitution returns (returnValue[] memory) {
        bytes32[] storage services = users[user][msg.sender].allServices;
        uint totalDelegations = 0;

        for (uint i = 0; i < services.length; i++) {
            totalDelegations += users[user][msg.sender].services[services[i]].delegatedAddresses.length;
        }

        returnValue[] memory result = new returnValue[](totalDelegations);
        uint index = 0;

        for (uint i = 0; i < services.length; i++) {
            address[] storage delegatedAddresses = users[user][msg.sender].services[services[i]].delegatedAddresses;
            for (uint j = 0; j < delegatedAddresses.length; j++) {
                result[index] = returnValue(delegatedAddresses[j], services[i]);
                index++;
            }
        }

        return result;
    }

    function isValidService(address institution, string memory serviceName) public view returns (bool) {
        bytes32 serviceHash = hash(serviceName);
        return institutionServices[institution][serviceHash];
    }

    function isAuthorizedUser(address user) public view onlyOwner returns (bool) {
        return authorizedUsers[user];
    }

    function isAuthorizedInstitution(address institution) public view onlyOwner returns (bool) {
        return authorizedInstitutions[institution];
    }
}