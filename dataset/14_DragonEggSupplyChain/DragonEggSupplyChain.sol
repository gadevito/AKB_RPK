// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DragonEggSupplyChain {
    struct Egg {
        uint256 id;
        string breed;
        string discoveryDate;
        address[] owners;
        string[] custodyHistory;
        bool verified;
    }

    address[] public signatories;
    mapping(address => bool) public isSignatory;
    uint256 public requiredSignatures;
    uint256 public registrationFee;
    uint256 public transferFee;

    mapping(uint256 => Egg) private eggs;
    mapping(uint256 => address[]) private eggVerifiers;
    mapping(address => uint256) public balances;

    constructor(
        address[] memory _signatories,
        uint256 _requiredSignatures,
        uint256 _registrationFee,
        uint256 _transferFee
    ) {
        require(_signatories.length > 0, "At least one signatory required");
        require(
            _requiredSignatures > 0 &&
                _requiredSignatures <= _signatories.length,
            "Invalid number of required signatures"
        );

        for (uint i = 0; i < _signatories.length; i++) {
            require(!isSignatory[_signatories[i]], "Duplicate signatory");
            signatories.push(_signatories[i]);
            isSignatory[_signatories[i]] = true;
        }
        requiredSignatures = _requiredSignatures;
        registrationFee = _registrationFee;
        transferFee = _transferFee;
    }

    modifier onlySignatory() {
        require(isSignatory[msg.sender], "Not a signatory");
        _;
    }

    function updateFees(
        uint256 newRegistrationFee,
        uint256 newTransferFee
    ) public onlySignatory {
        registrationFee = newRegistrationFee;
        transferFee = newTransferFee;
    }

    function registerEgg(
        uint256 id,
        string memory breed,
        string memory discoveryDate,
        address[] memory signers
    ) public payable {
        require(msg.value >= registrationFee, "Insufficient registration fee");
        require(eggs[id].id == 0, "Egg already registered");

        uint256 signatures = countSignatures(signers);
        require(signatures >= requiredSignatures, "Not enough signatures");

        eggs[id] = Egg({
            id: id,
            breed: breed,
            discoveryDate: discoveryDate,
            owners: new address[](0),
            custodyHistory: new string[](0),
            verified: false
        });
        eggs[id].owners[0] = msg.sender;

        balances[address(this)] += msg.value;
    }

    function transferOwnership(
        uint256 id,
        address newOwner,
        address[] memory signers
    ) public payable {
        require(msg.value >= transferFee, "Insufficient transfer fee");
        require(isOwner(id, msg.sender), "Not the owner");

        uint256 signatures = countSignatures(signers);
        require(signatures >= requiredSignatures, "Not enough signatures");

        eggs[id].owners.push(newOwner);
        eggs[id].custodyHistory.push("Ownership transferred to new owner");

        balances[address(this)] += msg.value;
    }

    function verifyEgg(uint256 id) public onlySignatory {
        require(eggs[id].id != 0, "Egg not registered");
        require(!eggs[id].verified, "Egg already verified");
        eggs[id].verified = true;
        eggVerifiers[id].push(msg.sender);
    }

    function unverifyEgg(uint256 id) public onlySignatory {
        require(eggs[id].id != 0, "Egg not registered");
        require(eggs[id].verified, "Egg not verified");
        eggs[id].verified = false;
    }

    function getEggInfo(
        uint256 id
    )
        public
        view
        returns (
            string memory breed,
            string memory discoveryDate,
            address[] memory owners,
            string[] memory custodyHistory,
            bool verified
        )
    {
        Egg storage egg = eggs[id];
        return (
            egg.breed,
            egg.discoveryDate,
            egg.owners,
            egg.custodyHistory,
            egg.verified
        );
    }

    function getVerifiers(uint256 id) public view returns (address[] memory) {
        return eggVerifiers[id];
    }

    function isOwner(uint256 id, address account) internal view returns (bool) {
        address[] memory owners = eggs[id].owners;
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == account) {
                return true;
            }
        }
        return false;
    }

    function countSignatures(
        address[] memory signers
    ) internal view returns (uint256) {
        uint256 count = 0;
        for (uint i = 0; i < signers.length; i++) {
            if (isSignatory[signers[i]]) {
                count++;
            }
        }
        return count;
    }

    function withdrawFunds(uint256 amount) public onlySignatory {
        require(balances[address(this)] >= amount, "Insufficient funds");
        payable(msg.sender).transfer(amount);
        balances[address(this)] -= amount;
    }

    receive() external payable {
        balances[address(this)] += msg.value;
    }
}
