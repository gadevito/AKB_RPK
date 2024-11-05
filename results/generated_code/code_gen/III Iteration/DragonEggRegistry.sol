pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DragonEggRegistry {
    using SafeMath for uint256;

    uint256 public eggCount;
    uint256 public registrationFee;
    uint256 public transferFee;
    address[] public signatories;
    uint256 public requiredSignatures;
    uint256 public accumulatedFees;

    struct DragonEgg {
        string breed;
        uint256 discoveryDate;
        address owner;
    }

    struct Verification {
        bool isVerified;
        address verifier;
        uint256 timestamp;
    }

    mapping(uint256 => DragonEgg) public eggs;
    mapping(uint256 => address[]) public eggOwners;
    mapping(uint256 => address[]) public eggCustody;
    mapping(uint256 => Verification) public eggVerifications;

    event EggRegistered(uint256 eggId, string breed, uint256 discoveryDate, address owner);
    event EggTransferred(uint256 eggId, address from, address to);
    event EggVerified(uint256 eggId, address verifier);
    event EggUnverified(uint256 eggId, address verifier);
    event FeesUpdated(uint256 registrationFee, uint256 transferFee);
    event FeesWithdrawn(address signatory, uint256 amount);

    modifier onlySignatory() {
        require(isSignatory(msg.sender), "Caller is not a signatory");
        _;
    }

    modifier validEggId(uint256 eggId) {
        require(eggs[eggId].discoveryDate != 0, "Invalid egg ID");
        _;
    }

    modifier hasRequiredSignatures(uint256 eggId) {
        require(getSignaturesCount(eggId) >= requiredSignatures, "Not enough signatories");
        _;
    }

    constructor(
        uint256 _registrationFee,
        uint256 _transferFee,
        address[] memory _signatories,
        uint256 _requiredSignatures
    ) {
        registrationFee = _registrationFee;
        transferFee = _transferFee;
        signatories = _signatories;
        requiredSignatures = _requiredSignatures;
    }

    function isSignatory(address _address) internal view returns (bool) {
        for (uint256 i = 0; i < signatories.length; i++) {
            if (signatories[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function getSignaturesCount(uint256 eggId) internal view returns (uint256) {
        // Placeholder for actual implementation
        return 0;
    }

function registerEgg(uint256 eggId, string memory breed, uint256 discoveryDate, address initialOwner) public payable {
    require(msg.value >= registrationFee, "Insufficient registration fee");
    require(eggs[eggId].discoveryDate == 0, "Egg ID already exists");

    eggCount = eggCount + 1;

    DragonEgg storage newEgg = eggs[eggId];
    newEgg.breed = breed;
    newEgg.discoveryDate = discoveryDate;
    newEgg.owner = initialOwner;

    eggOwners[eggId].push(initialOwner);
    eggCustody[eggId].push(initialOwner);

    accumulatedFees += msg.value;

    emit EggRegistered(eggId, breed, discoveryDate, initialOwner);
}


function transferEgg(uint256 eggId, address newOwner) public payable {
    // Check if the msg.value is equal to the transferFee
    require(msg.value == transferFee, "Incorrect transfer fee");

    // Verify that the eggId is valid and exists in the eggs mapping
    require(eggs[eggId].discoveryDate != 0, "Egg does not exist");

    // Ensure the caller is the current owner of the dragon egg
    address[] storage owners = eggOwners[eggId];
    require(owners[owners.length - 1] == msg.sender, "Caller is not the current owner");

    // Update the eggOwners mapping to include the new owner
    owners.push(newOwner);

    // Update the eggCustody mapping to reflect the transfer
    address[] storage custody = eggCustody[eggId];
    custody.push(newOwner);

    // Increment the accumulatedFees by the transferFee
    accumulatedFees = accumulatedFees + msg.value;

    // Emit the EggTransferred event
    emit EggTransferred(eggId, msg.sender, newOwner);
}


function verifyEgg(uint256 eggId) public onlySignatory validEggId(eggId) hasRequiredSignatures(eggId) {
    Verification storage verification = eggVerifications[eggId];

    require(!verification.isVerified, "Egg is already verified");

    verification.isVerified = true;
    verification.verifier = msg.sender;
    verification.timestamp = block.timestamp;

    emit EggVerified(eggId, msg.sender);
}


function unverifyEgg(uint256 eggId) public onlySignatory validEggId(eggId) hasRequiredSignatures(eggId) {
    // Check if the egg is currently verified
    Verification storage verification = eggVerifications[eggId];
    bool isVerified = verification.isVerified;
    require(isVerified, "Egg is not currently verified");

    // Update the verification status to unverified
    verification.isVerified = false;
    verification.verifier = address(0);
    verification.timestamp = 0;

    // Emit the EggUnverified event
    emit EggUnverified(eggId, msg.sender);
}


function updateFees(uint256 newRegistrationFee, uint256 newTransferFee) public onlySignatory hasRequiredSignatures(newRegistrationFee) {
    registrationFee = newRegistrationFee;
    transferFee = newTransferFee;
    emit FeesUpdated(newRegistrationFee, newTransferFee);
}


function withdrawFees() public onlySignatory hasRequiredSignatures(0) {
    uint256 fees = accumulatedFees;
    require(fees > 0, "No accumulated fees to withdraw");

    accumulatedFees = 0;

    (bool success,) = payable(msg.sender).call{value: fees}("");
    require(success, "Transfer failed");

    emit FeesWithdrawn(msg.sender, fees);
}


function getEggDetails(uint256 eggId) public view returns (string memory breed, uint256 discoveryDate, address[] memory ownershipHistory, address[] memory custodyHistory, bool isVerified, address verifier) {
    // Validate that the eggId exists
    require(bytes(eggs[eggId].breed).length != 0, "Egg does not exist");

    // Retrieve the breed and discovery date
    DragonEgg storage egg = eggs[eggId];
    string memory eggBreed = egg.breed;
    uint256 eggDiscoveryDate = egg.discoveryDate;

    // Retrieve the ownership history
    address[] memory eggOwnershipHistory = eggOwners[eggId];

    // Retrieve the custody history
    address[] memory eggCustodyHistory = eggCustody[eggId];

    // Retrieve the verification status and verifier details
    Verification storage verification = eggVerifications[eggId];
    bool eggIsVerified = verification.isVerified;
    address eggVerifier = verification.verifier;

    // Return the retrieved details
    return (eggBreed, eggDiscoveryDate, eggOwnershipHistory, eggCustodyHistory, eggIsVerified, eggVerifier);
}


function getVerifierDetails(uint256 eggId) public view returns (address verifier, bool isVerified) {
    // Validate that the eggId exists
    require(bytes(eggs[eggId].breed).length != 0, "Egg does not exist");

    // Retrieve the verification details
    Verification storage verification = eggVerifications[eggId];
    address verifierAddress = verification.verifier;
    bool verificationStatus = verification.isVerified;

    // Return the verifier's address and the verification status
    return (verifierAddress, verificationStatus);
}


}