// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract IdentityVerification {
    struct Identity {
        string fullName;
        uint idNumber;
        bool isVerified;
    }

    mapping(address => Identity) public identities;

    address public admin;

    event IdentityVerified(address indexed user);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function registerIdentity(string memory _fullName, uint _idNumber) external {
        identities[msg.sender] = Identity({
            fullName: _fullName,
            idNumber: _idNumber,
            isVerified: false
        });
    }

    function verifyIdentity(address _user) external onlyAdmin {
        require(bytes(identities[_user].fullName).length != 0, "Identity not registered");
        identities[_user].isVerified = true;
        emit IdentityVerified(_user);
    }

    function getIdentity(address _user) external view returns (string memory, uint, bool) {
        Identity memory identity = identities[_user];
        return (identity.fullName, identity.idNumber, identity.isVerified);
    }
}