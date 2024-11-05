pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DragonEggRegistry {
    using SafeMath for uint256;

    uint256 public eggCounter;
    uint256 public registrationFee;
    uint256 public transferFee;
    address[] public signatories;

    mapping(uint256 => address) public eggVerifierDetails;
    mapping(uint256 => bool) public eggVerificationStatus;
    mapping(uint256 => address[]) public eggOwnershipHistory;
    mapping(uint256 => address[]) public eggCustodyHistory;
    mapping(uint256 => Egg) public eggs;
    mapping(uint256 => address) public signatoryApprovals;

    struct Egg {
        string breed;
        uint256 discoveryDate;
    }

    event EggRegistered(uint256 eggId, string breed, uint256 discoveryDate, address initialOwner);
    event EggTransferred(uint256 eggId, address from, address to);
    event EggVerified(uint256 eggId, address verifier);
    event EggUnverified(uint256 eggId, address verifier);
    event FeesUpdated(uint256 registrationFee, uint256 transferFee);
    event FeesWithdrawn(address signatory, uint256 amount);

    modifier onlySignatory() {
        require(isSignatory(msg.sender), "Caller is not a signatory");
        _;
    }

    modifier eggExists(uint256 eggId) {
        require(eggs[eggId].discoveryDate != 0, "Egg does not exist");
        _;
    }

    constructor(uint256 _registrationFee, uint256 _transferFee, address[] memory _signatories) {
        registrationFee = _registrationFee;
        transferFee = _transferFee;
        signatories = _signatories;
    }

    function isSignatory(address _address) internal view returns (bool) {
        for (uint256 i = 0; i < signatories.length; i++) {
            if (signatories[i] == _address) {
                return true;
            }
        }
        return false;
    }

function registerEgg(string memory breed, uint256 discoveryDate, address initialOwner) public payable {
    require(msg.value == registrationFee, "Incorrect registration fee");
    require(initialOwner != address(0), "Invalid initial owner address");

    eggCounter = eggCounter + 1;
    uint256 newEggId = eggCounter;

    Egg storage newEgg = eggs[newEggId];
    newEgg.breed = breed;
    newEgg.discoveryDate = discoveryDate;

    address[] storage ownershipHistory = eggOwnershipHistory[newEggId];
    ownershipHistory.push(initialOwner);

    address[] storage custodyHistory = eggCustodyHistory[newEggId];
    custodyHistory.push(initialOwner);

    emit EggRegistered(newEggId, breed, discoveryDate, initialOwner);
}


function transferEgg(uint256 eggId, address newOwner) external payable {
    // Ensure the dragon egg exists
    require(eggs[eggId].discoveryDate != 0, "Egg does not exist");

    // Ensure the caller is the current owner of the dragon egg
    address currentOwner = eggOwnershipHistory[eggId][eggOwnershipHistory[eggId].length - 1];
    require(msg.sender == currentOwner, "Caller is not the current owner");

    // Ensure the transfer fee is paid
    require(msg.value == transferFee, "Incorrect transfer fee");

    // Update the ownership of the dragon egg to the new owner
    eggOwnershipHistory[eggId].push(newOwner);

    // Emit the EggTransferred event
    emit EggTransferred(eggId, currentOwner, newOwner);
}


function verifyEgg(uint256 eggId) public onlySignatory eggExists(eggId) {
    bool isVerified = eggVerificationStatus[eggId];
    require(!isVerified, "Egg is already verified");

    eggVerificationStatus[eggId] = true;
    eggVerifierDetails[eggId] = msg.sender;

    emit EggVerified(eggId, msg.sender);
}


function unverifyEgg(uint256 eggId) external onlySignatory eggExists(eggId) {
    bool isVerified = eggVerificationStatus[eggId];
    require(isVerified, "Egg is not currently verified");

    eggVerificationStatus[eggId] = false;

    address verifier = msg.sender;
    eggVerifierDetails[eggId] = verifier;

    emit EggUnverified(eggId, verifier);
}


function updateFees(uint256 newRegistrationFee, uint256 newTransferFee) external onlySignatory {
    registrationFee = newRegistrationFee;
    transferFee = newTransferFee;
    emit FeesUpdated(newRegistrationFee, newTransferFee);
}


function withdrawFees() external onlySignatory {
    uint256 contractBalance = address(this).balance;
    require(contractBalance > 0, "No funds available for withdrawal");

    uint256 signatoryCount = signatories.length;
    require(signatoryCount > 0, "No signatories available");

    uint256 share = contractBalance / signatoryCount;

    (bool success,) = payable(msg.sender).call{value: share}("");
    require(success, "Transfer failed");

    emit FeesWithdrawn(msg.sender, share);
}


function getEggDetails(uint256 eggId) public view eggExists(eggId) returns (string memory breed, uint256 discoveryDate, address[] memory ownershipHistory, address[] memory custodyHistory, bool isVerified) {
    // Retrieve the egg details
    Egg storage egg = eggs[eggId];
    string memory eggBreed = egg.breed;
    uint256 eggDiscoveryDate = egg.discoveryDate;

    // Retrieve the ownership and custody history
    address[] memory eggOwnershipHistory = eggOwnershipHistory[eggId];
    address[] memory eggCustodyHistory = eggCustodyHistory[eggId];

    // Retrieve the verification status
    bool eggIsVerified = eggVerificationStatus[eggId];

    // Return the details
    return (eggBreed, eggDiscoveryDate, eggOwnershipHistory, eggCustodyHistory, eggIsVerified);
}


function getVerifierDetails(uint256 eggId) public view returns (address) {
    require(eggVerificationStatus[eggId], "Egg does not exist");

    address verifier = eggVerifierDetails[eggId];
    return verifier;
}


}