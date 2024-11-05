pragma solidity >=0.4.22 <0.9.0;

contract IdentityVerification {
    address public admin;

    struct Identity {
        string fullName;
        uint idNumber;
        bool verified;
    }

    mapping(address => Identity) public identities;

    event IdentityVerified(address indexed user);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

function registerIdentity(string memory _fullName, uint _idNumber) external {
    // Check if the identity for the msg.sender already exists
    Identity storage existingIdentity = identities[msg.sender];
    require(existingIdentity.idNumber == 0, "Identity already registered");

    // Create a new Identity struct
    Identity storage newIdentity = identities[msg.sender];
    newIdentity.fullName = _fullName;
    newIdentity.idNumber = _idNumber;
    newIdentity.verified = false;
}


function verifyIdentity(address _user) external onlyAdmin {
    // Check if the user exists in the identities mapping
    Identity storage identity = identities[_user];
    require(identity.idNumber != 0, "User does not exist");

    // Check if the user's identity is already verified
    require(!identity.verified, "Identity already verified");

    // Set the verified status to true
    identity.verified = true;

    // Emit the IdentityVerified event
    emit IdentityVerified(_user);
}


function getIdentity(address _user) external view returns (string memory, uint, bool) {
    Identity storage identity = identities[_user];
    string memory fullName = identity.fullName;
    uint idNumber = identity.idNumber;
    bool verified = identity.verified;

    require(idNumber != 0, "Identity does not exist");

    return (fullName, idNumber, verified);
}


}