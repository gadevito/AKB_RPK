pragma solidity >=0.4.22 <0.9.0;

contract RentalAgreement {
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
    event RentPaid(address tenant, uint amount, uint paymentId);
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
    require(msg.sender != landlord, "Landlord cannot confirm the agreement");
    require(agreementState == State.Created, "Agreement is not in Created state");

    tenant = msg.sender;
    agreementState = State.Started;

    emit AgreementConfirmed(tenant);
}


function payRent() public payable onlyTenant inState(State.Started) {
    require(msg.value == rentAmount, "Incorrect rent amount");

    uint currentPaymentCount = paymentCount;
    RentPayment storage newPayment = rentPayments[currentPaymentCount];
    newPayment.amount = msg.value;
    newPayment.timestamp = block.timestamp;

    paymentCount = paymentCount + 1;

    emit RentPaid(msg.sender, msg.value, currentPaymentCount);

    (bool success,) = payable(landlord).call{value: msg.value}("");
    require(success, "Transfer failed");
}


function terminateAgreement() public onlyLandlord inState(State.Started) {
    agreementState = State.Terminated;
    emit AgreementTerminated();
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
    address tempTenant = tenant;
    return tempTenant;
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