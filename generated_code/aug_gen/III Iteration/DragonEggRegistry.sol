pragma solidity >=0.4.22 <0.9.0;

contract DragonEggRegistry {
    struct DragonEgg {
        uint256 id;
        string breed;
        uint256 discoveryDate;
        address initialOwner;
        bool verified;
        address[] verifiers;
        address[] ownershipHistory;
        address[] custodyHistory;
    }

    address[] public signatories;
    uint256 public registrationFee;
    uint256 public transferFee;
    mapping(uint256 => DragonEgg) public dragonEggs;
    mapping(address => uint256) public accumulatedFees;

    event DragonEggRegistered(uint256 id, string breed, uint256 discoveryDate, address initialOwner);
    event OwnershipTransferred(uint256 id, address from, address to);
    event DragonEggVerified(uint256 id, address verifier);
    event DragonEggUnverified(uint256 id, address verifier);
    event FeesUpdated(uint256 registrationFee, uint256 transferFee);
    event FeesWithdrawn(address signatory, uint256 amount);

    modifier onlySignatory() {
        require(isSignatory(msg.sender), "Not a signatory");
        _;
    }

    constructor(address[] memory _signatories, uint256 _registrationFee, uint256 _transferFee) {
        signatories = _signatories;
        registrationFee = _registrationFee;
        transferFee = _transferFee;
    }

    function isSignatory(address _address) public view returns (bool) {
        for (uint256 i = 0; i < signatories.length; i++) {
            if (signatories[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function registerDragonEgg(uint256 _id, string memory _breed, uint256 _discoveryDate, address _initialOwner) public payable {
        require(msg.value == registrationFee, "Incorrect registration fee");
        require(dragonEggs[_id].id == 0, "Dragon egg already registered");
        require(_initialOwner != address(0), "Invalid initial owner address");

        DragonEgg storage newEgg = dragonEggs[_id];
        newEgg.id = _id;
        newEgg.breed = _breed;
        newEgg.discoveryDate = _discoveryDate;
        newEgg.initialOwner = _initialOwner;
        newEgg.ownershipHistory.push(_initialOwner);
        newEgg.custodyHistory.push(_initialOwner);

        accumulatedFees[msg.sender] += msg.value;

        emit DragonEggRegistered(_id, _breed, _discoveryDate, _initialOwner);
    }

    function transferOwnership(uint256 _id, address _newOwner) public payable {
        require(msg.value == transferFee, "Incorrect transfer fee");
        require(dragonEggs[_id].id != 0, "Dragon egg not registered");
        require(dragonEggs[_id].ownershipHistory[dragonEggs[_id].ownershipHistory.length - 1] == msg.sender, "Not the current owner");
        require(_newOwner != address(0), "Invalid new owner address");

        dragonEggs[_id].ownershipHistory.push(_newOwner);
        dragonEggs[_id].custodyHistory.push(_newOwner);

        accumulatedFees[msg.sender] += msg.value;

        emit OwnershipTransferred(_id, msg.sender, _newOwner);
    }

    function verifyDragonEgg(uint256 _id) public onlySignatory {
        require(dragonEggs[_id].id != 0, "Dragon egg not registered");
        require(!dragonEggs[_id].verified, "Dragon egg already verified");

        dragonEggs[_id].verified = true;
        dragonEggs[_id].verifiers.push(msg.sender);

        emit DragonEggVerified(_id, msg.sender);
    }

    function unverifyDragonEgg(uint256 _id) public onlySignatory {
        require(dragonEggs[_id].id != 0, "Dragon egg not registered");
        require(dragonEggs[_id].verified, "Dragon egg not verified");

        dragonEggs[_id].verified = false;

        emit DragonEggUnverified(_id, msg.sender);
    }

    function updateFees(uint256 _registrationFee, uint256 _transferFee) public onlySignatory {
        require(_registrationFee > 0, "Registration fee must be greater than zero");
        require(_transferFee > 0, "Transfer fee must be greater than zero");

        registrationFee = _registrationFee;
        transferFee = _transferFee;

        emit FeesUpdated(_registrationFee, _transferFee);
    }

    function withdrawFees() public onlySignatory {
        uint256 amount = accumulatedFees[msg.sender];
        require(amount > 0, "No fees to withdraw");

        accumulatedFees[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit FeesWithdrawn(msg.sender, amount);
    }

    function getDragonEggDetails(uint256 _id) public view returns (string memory, uint256, address, bool, address[] memory, address[] memory, address[] memory) {
        require(dragonEggs[_id].id != 0, "Dragon egg not registered");

        DragonEgg storage egg = dragonEggs[_id];
        return (egg.breed, egg.discoveryDate, egg.initialOwner, egg.verified, egg.verifiers, egg.ownershipHistory, egg.custodyHistory);
    }

    function getVerifierDetails(uint256 _id) public view returns (address[] memory) {
        return dragonEggs[_id].verifiers;
    }
}