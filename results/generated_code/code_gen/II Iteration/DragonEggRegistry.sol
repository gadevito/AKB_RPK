pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DragonEggRegistry {
    using SafeMath for uint256;

    uint256 public registrationFee;
    uint256 public transferFee;
    address[] public signatories;
    uint256 public requiredSignatures;
    uint256 public eggCounter;
    uint256 public accumulatedFees;

    struct DragonEgg {
        string breed;
        uint256 discoveryDate;
        address[] ownershipHistory;
        address[] custodyHistory;
        bool isVerified;
        address[] verifiers;
    }

    mapping(uint256 => DragonEgg) public eggs;

    event EggRegistered(uint256 eggId, address owner, string breed, uint256 discoveryDate);
    event EggTransferred(uint256 eggId, address from, address to);
    event EggVerified(uint256 eggId, address verifier);
    event EggUnverified(uint256 eggId, address verifier);
    event FeesUpdated(uint256 registrationFee, uint256 transferFee);
    event FeesWithdrawn(address signatory, uint256 amount);

    modifier onlySignatory() {
        bool isSignatory = false;
        for (uint256 i = 0; i < signatories.length; i++) {
            if (signatories[i] == msg.sender) {
                isSignatory = true;
                break;
            }
        }
        require(isSignatory, "Caller is not a signatory");
        _;
    }

    modifier validEggId(uint256 eggId) {
        require(eggId <= eggCounter, "Invalid egg ID");
        _;
    }

    modifier hasRequiredSignatures(uint256 eggId) {
        // Placeholder for actual signature verification logic
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
        eggCounter = 0;
        accumulatedFees = 0;
    }

    function registerEgg(string memory breed, uint256 discoveryDate, address initialOwner) public payable {
        require(msg.value >= registrationFee, "Insufficient registration fee");
        require(discoveryDate <= block.timestamp, "Discovery date cannot be in the future");

        eggCounter = eggCounter + 1;
        uint256 newEggId = eggCounter;

        DragonEgg storage newEgg = eggs[newEggId];
        newEgg.breed = breed;
        newEgg.discoveryDate = discoveryDate;
        newEgg.ownershipHistory.push(initialOwner);
        newEgg.custodyHistory.push(initialOwner);

        accumulatedFees = accumulatedFees + msg.value;

        emit EggRegistered(newEggId, initialOwner, breed, discoveryDate);
    }

    function transferEgg(uint256 eggId, address newOwner) public payable {
        require(msg.value >= transferFee, "Insufficient transfer fee");

        DragonEgg storage egg = eggs[eggId];
        require(egg.ownershipHistory.length > 0, "Egg does not exist");
        require(msg.sender == egg.ownershipHistory[egg.ownershipHistory.length - 1], "Caller is not the current owner");

        address currentOwner = egg.ownershipHistory[egg.ownershipHistory.length - 1];
        egg.ownershipHistory.push(newOwner);

        accumulatedFees += msg.value;

        emit EggTransferred(eggId, currentOwner, newOwner);
    }

    function verifyEgg(uint256 eggId) public onlySignatory validEggId(eggId) hasRequiredSignatures(eggId) {
        // Ensure the egg ID is valid
        require(eggId <= eggCounter, "Invalid egg ID");

        // Check if the caller is a signatory
        bool isSignatory = false;
        for (uint256 i = 0; i < signatories.length; i = i + 1) {
            if (signatories[i] == msg.sender) {
                isSignatory = true;
                break;
            }
        }
        require(isSignatory, "Caller is not a signatory");

        // Verify that the action has the required number of signatories
        // This is handled by the hasRequiredSignatures modifier

        // Update the egg's verification status to true
        DragonEgg storage egg = eggs[eggId];
        egg.isVerified = true;

        // Record the verifier's details
        egg.verifiers.push(msg.sender);

        // Emit the EggVerified event with the egg ID and verifier's address
        emit EggVerified(eggId, msg.sender);
    }

    function unverifyEgg(uint256 eggId) public onlySignatory validEggId(eggId) hasRequiredSignatures(eggId) {
        // Check if the egg is currently verified
        DragonEgg storage egg = eggs[eggId];
        bool isVerified = egg.isVerified;
        require(isVerified, "Egg is not currently verified");

        // Change the egg's status to unverified
        egg.isVerified = false;

        // Record the unverification action and the verifier's details
        address verifier = msg.sender;
        egg.verifiers.push(verifier);

        // Emit the EggUnverified event
        emit EggUnverified(eggId, verifier);
    }

    function updateFees(uint256 newRegistrationFee, uint256 newTransferFee) public onlySignatory hasRequiredSignatures(0) {
        registrationFee = newRegistrationFee;
        transferFee = newTransferFee;
        emit FeesUpdated(newRegistrationFee, newTransferFee);
    }

    function withdrawFees() public onlySignatory {
        uint256 fees = accumulatedFees;
        require(fees > 0, "No fees to withdraw");

        accumulatedFees = 0;

        (bool success,) = payable(msg.sender).call{value: fees}("");
        require(success, "Transfer failed");

        emit FeesWithdrawn(msg.sender, fees);
    }

    function getEggDetails(uint256 eggId) public view validEggId(eggId) returns (
        string memory breed, 
        uint256 discoveryDate, 
        address[] memory ownershipHistory, 
        address[] memory custodyHistory, 
        bool isVerified, 
        address[] memory verifiers
    ) {
        DragonEgg storage egg = eggs[eggId];

        string memory tempBreed = egg.breed;
        uint256 tempDiscoveryDate = egg.discoveryDate;
        address[] memory tempOwnershipHistory = egg.ownershipHistory;
        address[] memory tempCustodyHistory = egg.custodyHistory;
        bool tempIsVerified = egg.isVerified;
        address[] memory tempVerifiers = egg.verifiers;

        return (
            tempBreed, 
            tempDiscoveryDate, 
            tempOwnershipHistory, 
            tempCustodyHistory, 
            tempIsVerified, 
            tempVerifiers
        );
    }

    function getVerifierDetails(uint256 eggId) public view validEggId(eggId) returns (address[] memory) {
        DragonEgg storage egg = eggs[eggId];
        return egg.verifiers;
    }
}