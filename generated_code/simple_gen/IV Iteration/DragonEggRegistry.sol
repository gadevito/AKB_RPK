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

    struct OwnershipHistory {
        address owner;
        uint256 transferDate;
    }

    struct CustodyHistory {
        address custodian;
        uint256 custodyDate;
    }

    address[] public signatories;
    uint256 public registrationFee;
    uint256 public transferFee;
    mapping(uint256 => DragonEgg) public dragonEggs;
    mapping(uint256 => OwnershipHistory[]) public ownershipHistories;
    mapping(uint256 => CustodyHistory[]) public custodyHistories;
    mapping(address => uint256) public accumulatedFees;

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

        ownershipHistories[_id].push(OwnershipHistory({
            owner: _initialOwner,
            transferDate: block.timestamp
        }));

        custodyHistories[_id].push(CustodyHistory({
            custodian: _initialOwner,
            custodyDate: block.timestamp
        }));

        accumulatedFees[address(this)] += msg.value;
    }

    function transferOwnership(uint256 _id, address _newOwner) public payable {
        require(msg.value == transferFee, "Incorrect transfer fee");
        require(dragonEggs[_id].id != 0, "Dragon egg not registered");
        require(ownershipHistories[_id][ownershipHistories[_id].length - 1].owner == msg.sender, "Only the current owner can transfer ownership");

        ownershipHistories[_id].push(OwnershipHistory({
            owner: _newOwner,
            transferDate: block.timestamp
        }));

        custodyHistories[_id].push(CustodyHistory({
            custodian: _newOwner,
            custodyDate: block.timestamp
        }));

        accumulatedFees[address(this)] += msg.value;
    }

    function verifyDragonEgg(uint256 _id) public onlySignatory {
        require(dragonEggs[_id].id != 0, "Dragon egg not registered");
        dragonEggs[_id].verified = true;
        dragonEggs[_id].verifier = msg.sender;
    }

    function unverifyDragonEgg(uint256 _id) public onlySignatory {
        require(dragonEggs[_id].id != 0, "Dragon egg not registered");
        dragonEggs[_id].verified = false;
        dragonEggs[_id].verifier = address(0);
    }

    function updateRegistrationFee(uint256 _newFee) public onlySignatory {
        registrationFee = _newFee;
    }

    function updateTransferFee(uint256 _newFee) public onlySignatory {
        transferFee = _newFee;
    }

    function withdrawFees() public onlySignatory {
        uint256 amount = accumulatedFees[address(this)];
        require(amount > 0, "No fees to withdraw");
        accumulatedFees[address(this)] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function getDragonEggDetails(uint256 _id) public view returns (string memory, uint256, address, bool, address) {
        DragonEgg memory egg = dragonEggs[_id];
        return (egg.breed, egg.discoveryDate, egg.initialOwner, egg.verified, egg.verifier);
    }

    function getOwnershipHistory(uint256 _id) public view returns (OwnershipHistory[] memory) {
        return ownershipHistories[_id];
    }

    function getCustodyHistory(uint256 _id) public view returns (CustodyHistory[] memory) {
        return custodyHistories[_id];
    }

    function getVerifierDetails(uint256 _id) public view returns (address) {
        return dragonEggs[_id].verifier;
    }
}