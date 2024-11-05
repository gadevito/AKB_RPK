pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DragonEggRegistry {
    using SafeMath for uint256;

    uint256 public registrationFee;
    uint256 public transferFee;
    address[] public signatories;
    uint256 public requiredSignatures;
    uint256 public accumulatedFees;
    uint256 public eggCount;

    struct DragonEgg {
        string breed;
        uint256 discoveryDate;
        address initialOwner;
        address currentOwner;
        address[] ownershipHistory;
        address[] custodyHistory;
        bool isVerified;
        address[] verifiers;
    }

    mapping(uint256 => DragonEgg) public dragonEggs;

    event DragonEggRegistered(uint256 eggId, string breed, uint256 discoveryDate, address initialOwner);
    event OwnershipTransferred(uint256 eggId, address from, address to);
    event DragonEggVerified(uint256 eggId, address verifier);
    event DragonEggUnverified(uint256 eggId, address verifier);
    event FeesUpdated(uint256 registrationFee, uint256 transferFee);
    event FeesWithdrawn(address signatory, uint256 amount);

    modifier onlySignatory() {
        require(isSignatory(msg.sender), "Caller is not a signatory");
        _;
    }

    modifier validSignatures(uint256 eggId) {
        require(hasValidSignatures(eggId), "Not enough valid signatures");
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

    function hasValidSignatures(uint256 eggId) internal view returns (bool) {
        // Implement logic to check if the required number of signatories have validated the action
        return true;
    }

function registerDragonEgg(uint256 eggId, string memory breed, uint256 discoveryDate, address initialOwner) public payable {
    require(msg.value >= registrationFee, "Insufficient registration fee");
    require(dragonEggs[eggId].discoveryDate == 0, "Egg ID already registered");

    DragonEgg storage newEgg = dragonEggs[eggId];
    newEgg.breed = breed;
    newEgg.discoveryDate = discoveryDate;
    newEgg.initialOwner = initialOwner;

    eggCount = eggCount + 1;
    accumulatedFees = accumulatedFees + msg.value;

    emit DragonEggRegistered(eggId, breed, discoveryDate, initialOwner);
}


function transferOwnership(uint256 eggId, address newOwner) public payable {
    // Check if the dragon egg exists
    DragonEgg storage egg = dragonEggs[eggId];
    require(egg.discoveryDate != 0, "Dragon egg does not exist");

    // Check if the caller is the current owner
    address currentOwner = egg.currentOwner;
    require(msg.sender == currentOwner, "Caller is not the current owner");

    // Ensure the msg.value is equal to or greater than the transferFee
    require(msg.value >= transferFee, "Insufficient transfer fee");

    // Update the ownership of the dragon egg to the newOwner
    egg.currentOwner = newOwner;

    // Record the transfer in the ownership history
    egg.ownershipHistory.push(newOwner);

    // Accumulate the transfer fee into accumulatedFees
    accumulatedFees = accumulatedFees + msg.value;

    // Emit the OwnershipTransferred event
    emit OwnershipTransferred(eggId, currentOwner, newOwner);
}


function verifyDragonEgg(uint256 eggId) public onlySignatory validSignatures(eggId) {
    // Check if the dragon egg with the given eggId exists
    DragonEgg storage egg = dragonEggs[eggId];
    require(egg.discoveryDate != 0, "Dragon egg does not exist");

    // Ensure the dragon egg is not already verified
    bool isVerified = egg.isVerified;
    require(!isVerified, "Dragon egg is already verified");

    // Mark the dragon egg as verified
    egg.isVerified = true;

    // Record the verifier's address
    egg.verifiers.push(msg.sender);

    // Emit the DragonEggVerified event with the eggId and the verifier's address
    emit DragonEggVerified(eggId, msg.sender);
}


function unverifyDragonEgg(uint256 eggId) public onlySignatory validSignatures(eggId) {
    // Check if the dragon egg with the given eggId exists
    DragonEgg storage dragonEgg = dragonEggs[eggId];
    require(dragonEgg.discoveryDate != 0, "Dragon egg does not exist");

    // Ensure the dragon egg is currently verified
    bool isVerified = dragonEgg.isVerified;
    require(isVerified, "Dragon egg is not currently verified");

    // Update the verification status of the dragon egg to unverified
    dragonEgg.isVerified = false;

    // Record the details of the signatory who performed the unverification
    dragonEgg.verifiers.push(msg.sender);

    // Emit the DragonEggUnverified event with the eggId and the address of the signatory
    emit DragonEggUnverified(eggId, msg.sender);
}


function updateFees(uint256 newRegistrationFee, uint256 newTransferFee) public onlySignatory validSignatures(0) {
    registrationFee = newRegistrationFee;
    transferFee = newTransferFee;
    emit FeesUpdated(newRegistrationFee, newTransferFee);
}


function withdrawFees() public onlySignatory {
    uint256 fees = accumulatedFees;
    require(fees > 0, "No accumulated fees to withdraw");

    accumulatedFees = 0;

    (bool success,) = payable(msg.sender).call{value: fees}("");
    require(success, "Transfer failed");

    emit FeesWithdrawn(msg.sender, fees);
}


function getDragonEggDetails(uint256 eggId) public view returns (string memory breed, uint256 discoveryDate, address[] memory ownershipHistory, address[] memory custodyHistory, bool isVerified, address[] memory verifiers) {
    // Check if the dragon egg exists
    DragonEgg storage egg = dragonEggs[eggId];
    require(egg.discoveryDate != 0, "Dragon egg does not exist");

    // Extract details
    string memory tempBreed = egg.breed;
    uint256 tempDiscoveryDate = egg.discoveryDate;
    address[] memory tempOwnershipHistory = egg.ownershipHistory;
    address[] memory tempCustodyHistory = egg.custodyHistory;
    bool tempIsVerified = egg.isVerified;
    address[] memory tempVerifiers = egg.verifiers;

    // Return the extracted details
    return (tempBreed, tempDiscoveryDate, tempOwnershipHistory, tempCustodyHistory, tempIsVerified, tempVerifiers);
}


function getVerifierDetails(uint256 eggId) public view returns (address[] memory) {
    // Check if the dragon egg exists
    DragonEgg storage dragonEgg = dragonEggs[eggId];
    require(dragonEgg.discoveryDate != 0, "Dragon egg does not exist");

    // Return the list of verifiers
    return dragonEgg.verifiers;
}


}