// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract RentalAgreement {
    address public landlord;
    address public tenant;
    uint256 public rentAmount;
    string public houseDetails;
    uint256 public creationTimestamp;
    enum State { Created, Started, Terminated }
    State public state;

    struct RentPayment {
        uint256 amount;
        uint256 timestamp;
    }

    RentPayment[] public rentPayments;

    event AgreementConfirmed(address tenant);
    event RentPaid(address tenant, uint256 amount, uint256 timestamp);
    event AgreementTerminated();

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only landlord can call this function");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only tenant can call this function");
        _;
    }

    modifier inState(State _state) {
        require(state == _state, "Invalid state for this action");
        _;
    }

    constructor(uint256 _rentAmount, string memory _houseDetails) {
        landlord = msg.sender;
        rentAmount = _rentAmount;
        houseDetails = _houseDetails;
        creationTimestamp = block.timestamp;
        state = State.Created;
    }

    function confirmAgreement() public inState(State.Created) {
        require(msg.sender != landlord, "Landlord cannot confirm the agreement");
        tenant = msg.sender;
        state = State.Started;
        emit AgreementConfirmed(tenant);
    }

    function payRent() public payable onlyTenant inState(State.Started) {
        require(msg.value == rentAmount, "Incorrect rent amount");
        rentPayments.push(RentPayment({
            amount: msg.value,
            timestamp: block.timestamp
        }));
        payable(landlord).transfer(msg.value);
        emit RentPaid(tenant, msg.value, block.timestamp);
    }

    function terminateAgreement() public onlyLandlord inState(State.Started) {
        state = State.Terminated;
        emit AgreementTerminated();
    }

    function getRentAmount() public view returns (uint256) {
        return rentAmount;
    }

    function getHouseDetails() public view returns (string memory) {
        return houseDetails;
    }

    function getLandlord() public view returns (address) {
        return landlord;
    }

    function getTenant() public view returns (address) {
        return tenant;
    }

    function getRentPayments() public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory amounts = new uint256[](rentPayments.length);
        uint256[] memory timestamps = new uint256[](rentPayments.length);
        for (uint256 i = 0; i < rentPayments.length; i++) {
            amounts[i] = rentPayments[i].amount;
            timestamps[i] = rentPayments[i].timestamp;
        }
        return (amounts, timestamps);
    }
}