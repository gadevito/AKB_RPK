pragma solidity >=0.4.22 <0.9.0;

contract DragonEggRegistry {
    struct DragonEgg {
        uint256 id;
        string breed;
        uint256 discoveryDate;
        address initialOwner;
        bool verified;
        address verifier;
    }

    struct OwnershipTransfer {
        address from;
        address to;
        uint256 timestamp;
    }

    address[] public signatories;
    uint256 public registrationFee;
    uint256 public transferFee;
    mapping(uint256 => DragonEgg) public dragonEggs;
    mapping(uint256 => OwnershipTransfer[]) public ownershipHistory;
    mapping(uint256 => address[]) public custodyHistory;
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

        dragonEggs[_id] = DragonEgg({
            id: _id,
            breed: _breed,
            discoveryDate: _discoveryDate,
            initialOwner: _initialOwner,
            verified: false,
            verifier: address(0)
        });

        custodyHistory[_id].push(_initialOwner);
        accumulatedFees[msg.sender] += msg.value;

        emit DragonEggRegistered(_id, _breed, _discoveryDate, _initialOwner);
    }

    function transferOwnership(uint256 _id, address _newOwner) public payable {
        require(msg.value == transferFee, "Incorrect transfer fee");
        require(dragonEggs[_id].id != 0, "Dragon egg not registered");
        require(dragonEggs[_id].initialOwner == msg.sender || isSignatory(msg.sender), "Not authorized to transfer");

        address previousOwner = custodyHistory[_id][custodyHistory[_id].length - 1];
        ownershipHistory[_id].push(OwnershipTransfer({
            from: previousOwner,
            to: _newOwner,
            timestamp: block.timestamp
        }));
        custodyHistory[_id].push(_newOwner);
        accumulatedFees[msg.sender] += msg.value;

        emit OwnershipTransferred(_id, previousOwner, _newOwner);
    }

    function verifyDragonEgg(uint256 _id) public onlySignatory {
        require(dragonEggs[_id].id != 0, "Dragon egg not registered");
        require(!dragonEggs[_id].verified, "Dragon egg already verified");

        dragonEggs[_id].verified = true;
        dragonEggs[_id].verifier = msg.sender;

        emit DragonEggVerified(_id, msg.sender);
    }

    function unverifyDragonEgg(uint256 _id) public onlySignatory {
        require(dragonEggs[_id].id != 0, "Dragon egg not registered");
        require(dragonEggs[_id].verified, "Dragon egg not verified");

        dragonEggs[_id].verified = false;
        dragonEggs[_id].verifier = address(0);

        emit DragonEggUnverified(_id, msg.sender);
    }

    function updateFees(uint256 _registrationFee, uint256 _transferFee) public onlySignatory {
        registrationFee = _registrationFee;
        transferFee = _transferFee;

        emit FeesUpdated(_registrationFee, _transferFee);
    }

    function withdrawFees() public onlySignatory {
        uint256 amount = accumulatedFees[msg.sender];
        require(amount > 0, "No fees to withdraw");

        accumulatedFees[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit FeesWithdrawn(msg.sender, amount);
    }

    function getDragonEggDetails(uint256 _id) public view returns (string memory breed, uint256 discoveryDate, address initialOwner, bool verified, address verifier) {
        DragonEgg memory egg = dragonEggs[_id];
        return (egg.breed, egg.discoveryDate, egg.initialOwner, egg.verified, egg.verifier);
    }

    function getOwnershipHistory(uint256 _id) public view returns (OwnershipTransfer[] memory) {
        return ownershipHistory[_id];
    }

    function getCustodyHistory(uint256 _id) public view returns (address[] memory) {
        return custodyHistory[_id];
    }

    function getVerifierDetails(uint256 _id) public view returns (address) {
        return dragonEggs[_id].verifier;
    }
}