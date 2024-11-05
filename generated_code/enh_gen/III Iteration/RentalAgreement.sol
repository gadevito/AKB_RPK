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

    RentPayment[] public payments;

    event AgreementConfirmed(address tenant);
    event AgreementTerminated();

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Caller is not the landlord");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Caller is not the tenant");
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
    require(msg.sender != landlord, "Caller is the landlord");
    require(agreementState == State.Created, "Agreement is not in Created state");

    tenant = msg.sender;
    agreementState = State.Started;

    emit AgreementConfirmed(tenant);
}


function payRent() public payable onlyTenant inState(State.Started) {
    require(msg.value == rentAmount, "Incorrect rent amount");

    RentPayment storage newPayment = payments.push();
    newPayment.amount = msg.value;
    newPayment.timestamp = block.timestamp;

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
    return landlord;
}


function viewTenant() public view returns (address) {
    return tenant;
}


function viewRentPayments() public view returns (RentPayment[] memory) {
    return payments;
}


}