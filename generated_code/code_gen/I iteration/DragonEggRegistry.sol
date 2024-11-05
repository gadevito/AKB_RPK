pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DragonEggRegistry {
    using SafeMath for uint256;

    uint256 public eggCounter;
    uint256 public registrationFee;
    uint256 public transferFee;
    address[] public signatories;
    uint256 public requiredSignatures;
    uint256 public accumulatedFees;

    struct DragonEgg {
        uint256 id;
        string breed;
        uint256 discoveryDate;
        address initialOwner;
        address currentOwner;
    }

    struct Verification {
        bool isVerified;
        address[] verifiers;
        address verifier;
    }

    mapping(uint256 => DragonEgg) public eggs;
    mapping(uint256 => Verification) public verifications;

    event EggRegistered(uint256 eggId, address owner);
    event EggTransferred(uint256 eggId, address from, address to);
    event EggVerified(uint256 eggId, address verifier);
    event EggUnverified(uint256 eggId, address verifier);
    event FeesUpdated(uint256 registrationFee, uint256 transferFee);
    event FeesWithdrawn(address signatory, uint256 amount);

    modifier onlySignatory() {
        // Modifier logic to ensure the caller is a signatory
        _;
    }

    modifier validSignatures(uint256 eggId) {
        // Modifier logic to ensure the required number of signatories have validated the action
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

function registerEgg(uint256 _eggId, string memory _breed, uint256 _discoveryDate, address _initialOwner) public payable {
    require(msg.value >= registrationFee, "Insufficient registration fee");
    require(eggs[_eggId].id == 0, "Egg ID already registered");

    DragonEgg storage newEgg = eggs[_eggId];
    newEgg.id = _eggId;
    newEgg.breed = _breed;
    newEgg.discoveryDate = _discoveryDate;
    newEgg.initialOwner = _initialOwner;
    newEgg.currentOwner = _initialOwner;

    eggCounter = eggCounter + 1;
    accumulatedFees = accumulatedFees + msg.value;

    emit EggRegistered(_eggId, _initialOwner);
}


function transferEgg(uint256 eggId, address newOwner) external payable {
    require(msg.value == transferFee, "Incorrect transfer fee");
    require(newOwner != address(0), "Invalid new owner address");

    DragonEgg storage egg = eggs[eggId];
    require(egg.currentOwner == msg.sender, "Caller is not the current owner");

    address previousOwner = egg.currentOwner;
    egg.currentOwner = newOwner;

    accumulatedFees = accumulatedFees + msg.value;

    emit EggTransferred(eggId, previousOwner, newOwner);
}


function verifyEgg(uint256 eggId) public onlySignatory validSignatures(eggId) {
    // Check if the egg with the given eggId exists
    DragonEgg storage egg = eggs[eggId];
    require(egg.id != 0, "Dragon egg does not exist");

    // Ensure the egg is not already verified
    Verification storage verification = verifications[eggId];
    require(!verification.isVerified, "Dragon egg is already verified");

    // Record the verification status and the verifier's details
    verification.isVerified = true;
    verification.verifiers.push(msg.sender);

    // Emit the EggVerified event with the eggId and the verifier's address
    emit EggVerified(eggId, msg.sender);
}


function unverifyEgg(uint256 eggId) public onlySignatory validSignatures(eggId) {
    // Check if the egg exists in the `eggs` mapping
    DragonEgg storage egg = eggs[eggId];
    require(egg.initialOwner != address(0), "Dragon egg does not exist");

    // Ensure the egg is currently verified
    Verification storage verification = verifications[eggId];
    require(verification.isVerified, "Dragon egg is not currently verified");

    // Update the verification status of the egg to unverified
    verification.isVerified = false;

    // Record the verifier details (signatory who unverifies)
    verification.verifiers.push(msg.sender);

    // Emit the `EggUnverified` event with the `eggId` and the address of the verifier
    emit EggUnverified(eggId, msg.sender);
}


function updateFees(uint256 newRegistrationFee, uint256 newTransferFee) external onlySignatory validSignatures(0) {
    // Update the registration fee
    registrationFee = newRegistrationFee;

    // Update the transfer fee
    transferFee = newTransferFee;

    // Emit the FeesUpdated event
    emit FeesUpdated(newRegistrationFee, newTransferFee);
}


function withdrawFees() external onlySignatory {
    uint256 fees = accumulatedFees;
    require(fees > 0, "No accumulated fees to withdraw");

    accumulatedFees = 0;

    (bool success,) = payable(msg.sender).call{value: fees}("");
    require(success, "Transfer failed");

    emit FeesWithdrawn(msg.sender, fees);
}


function getEggDetails(uint256 eggId) public view returns (uint256 id, string memory breed, uint256 discoveryDate, address initialOwner, address currentOwner, bool isVerified, address[] memory verifiers) {
    // Check if the egg exists
    DragonEgg storage egg = eggs[eggId];
    require(egg.id != 0, "Dragon egg does not exist");

    // Retrieve egg details
    id = egg.id;
    breed = egg.breed;
    discoveryDate = egg.discoveryDate;
    initialOwner = egg.initialOwner;
    currentOwner = egg.currentOwner;

    // Retrieve verification details
    Verification storage verification = verifications[eggId];
    isVerified = verification.isVerified;
    verifiers = verification.verifiers;

    return (id, breed, discoveryDate, initialOwner, currentOwner, isVerified, verifiers);
}


function getVerifierDetails(uint256 eggId) public view returns (address verifier, bool isVerified) {
    Verification storage verification = verifications[eggId];

    if (verification.verifiers.length == 0) {
        revert("Dragon egg does not exist");
    }

    verifier = verification.verifiers[verification.verifiers.length - 1];
    isVerified = verification.isVerified;

    return (verifier, isVerified);
}


}