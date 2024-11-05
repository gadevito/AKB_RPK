pragma solidity >=0.4.22 <0.9.0;

contract IdentityVerification {
    address public admin;

    struct Identity {
        string fullName;
        uint idNumber;
        bool isVerified;
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
    Identity storage identity = identities[msg.sender];

    require(bytes(identity.fullName).length == 0, "Identity already registered");

    identity.fullName = _fullName;
    identity.idNumber = _idNumber;
    identity.isVerified = false;
}


function verifyIdentity(address _user) external onlyAdmin {
    Identity storage userIdentity = identities[_user];

    require(bytes(userIdentity.fullName).length != 0, "User does not exist");

    userIdentity.isVerified = true;

    emit IdentityVerified(_user);
}


function getIdentity(address _user) public view returns (string memory, uint, bool) {
    Identity storage identity = identities[_user];
    string memory fullName = identity.fullName;
    uint idNumber = identity.idNumber;
    bool isVerified = identity.isVerified;
    return (fullName, idNumber, isVerified);
}


}