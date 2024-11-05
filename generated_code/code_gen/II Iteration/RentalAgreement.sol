pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RentalAgreement {
    using SafeMath for uint;

    address public landlord;
    address public tenant;
    uint public rentAmount;
    string public houseDetails;
    uint public creationTimestamp;
    enum State { Created, Started, Terminated }
    State public agreementState;

    struct RentPayment {
        uint amount;
        uint timestamp;
    }
    mapping(uint => RentPayment) public rentPayments;
    uint public paymentCount;

    event AgreementConfirmed(address tenant);

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only the landlord can call this function");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only the tenant can call this function");
        _;
    }

    modifier inState(State _state) {
        require(agreementState == _state, "Invalid state");
        _;
    }

    constructor() public {
        landlord = msg.sender;
        agreementState = State.Created;
    }

function setRentalAgreement(uint _rentAmount, string memory _houseDetails) public onlyLandlord inState(State.Created) {
    rentAmount = _rentAmount;
    houseDetails = _houseDetails;
    creationTimestamp = block.timestamp;
    agreementState = State.Created;
}


function confirmAgreement() public {
    // Check that the caller is not the landlord
    require(msg.sender != landlord, "Caller cannot be the landlord");

    // Check that the contract is in the Created state
    require(agreementState == State.Created, "Contract is not in the Created state");

    // Set the caller's address as the tenant
    tenant = msg.sender;

    // Change the agreement state to Started
    agreementState = State.Started;

    // Emit the AgreementConfirmed event with the tenant's address
    emit AgreementConfirmed(tenant);
}


function payRent() public payable onlyTenant inState(State.Started) {
    require(msg.sender == tenant, "Caller is not the tenant");
    require(agreementState == State.Started, "Contract is not in the Started state");
    require(msg.value == rentAmount, "Incorrect rent amount");

    RentPayment storage payment = rentPayments[paymentCount];
    payment.amount = msg.value;
    payment.timestamp = block.timestamp;

    paymentCount = paymentCount + 1;

    (bool success,) = payable(landlord).call{value: msg.value}("");
    require(success, "Transfer to landlord failed");

    // Optional: Emit an event for the rent payment
    // emit RentPaymentMade(tenant, msg.value, block.timestamp);
}


function terminateAgreement() public onlyLandlord inState(State.Started) {
    agreementState = State.Terminated;
    // Emit an event to signal that the agreement has been terminated (if defined)
    // emit AgreementTerminated(); // Uncomment and define this event if needed
}


function viewRentAmount() public view returns (uint) {
    return rentAmount;
}


function viewHouseDetails() public view returns (string memory) {
    return houseDetails;
}


function viewLandlord() public view returns (address) {
    address tempLandlord = landlord;
    return tempLandlord;
}


function viewTenant() public view returns (address) {
    return tenant;
}


function viewRentPayments() public view returns (RentPayment[] memory) {
    uint count = paymentCount;
    RentPayment[] memory payments = new RentPayment[](count);

    for (uint i = 0; i < count; i = i + 1) {
        RentPayment storage payment = rentPayments[i];
        payments[i] = RentPayment({
            amount: payment.amount,
            timestamp: payment.timestamp
        });
    }

    return payments;
}


}