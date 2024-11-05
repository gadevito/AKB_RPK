pragma solidity >=0.4.22 <0.9.0;

contract RentalAgreement {
    address payable public landlord;
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
        landlord = payable(msg.sender);
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
        require(msg.value == rentAmount, "Rent amount is incorrect");
        rentPayments.push(RentPayment({
            amount: msg.value,
            timestamp: block.timestamp
        }));
        landlord.transfer(msg.value);
        emit RentPaid(tenant, msg.value, block.timestamp);
    }

    function terminateAgreement() public onlyLandlord inState(State.Started) {
        state = State.Terminated;
        emit AgreementTerminated();
    }

    function getRentPayments() public view returns (RentPayment[] memory) {
        return rentPayments;
    }
}