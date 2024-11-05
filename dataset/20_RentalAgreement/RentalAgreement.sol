// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RentalAgreement {
    /* This declares a new complex type which will hold the paid rents */
    struct PaidRent {
        uint id /* The paid rent id */;
        uint value /* The amount of rent that is paid */;
    }

    PaidRent[] public paidrents;

    uint public createdTimestamp;
    uint public rent;
    /* Combination of zip code and house number */
    string public house;
    address public landlord;
    address public tenant;

    enum State {
        Created,
        Started,
        Terminated
    }
    State public state;

    constructor(uint _rent, string memory _house) {
        rent = _rent;
        house = _house;
        landlord = msg.sender;
        createdTimestamp = block.timestamp;
        state = State.Created;
    }

    modifier requireCondition(bool _condition) {
        require(_condition, "Condition not met");
        _;
    }

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only landlord can call this");
        _;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "Only tenant can call this");
        _;
    }

    modifier inState(State _state) {
        require(state == _state, "Invalid state");
        _;
    }

    /* Events for DApps to listen to */
    event AgreementConfirmed();

    event PaidRentEvent();

    event ContractTerminated();

    /* We also have some getters so that we can read the values
    from the blockchain at any time */
    function getPaidRents() internal view returns (PaidRent[] memory) {
        return paidrents;
    }

    function getHouse() external view returns (string memory) {
        return house;
    }

    function getLandlord() external view returns (address) {
        return landlord;
    }

    function getTenant() external view returns (address) {
        return tenant;
    }

    function getRent() external view returns (uint) {
        return rent;
    }

    function getContractCreated() external view returns (uint) {
        return createdTimestamp;
    }

    function getContractAddress() external view returns (address) {
        return address(this);
    }

    function getState() external view returns (State) {
        return state;
    }

    /* Confirm the lease agreement as tenant */
    function confirmAgreement()
        external
        inState(State.Created)
        requireCondition(msg.sender != landlord)
    {
        emit AgreementConfirmed();
        tenant = msg.sender;
        state = State.Started;
    }

    function payRent()
        external
        payable
        onlyTenant
        inState(State.Started)
        requireCondition(msg.value == rent)
    {
        emit PaidRentEvent();
        payable(landlord).transfer(msg.value);
        paidrents.push(PaidRent({id: paidrents.length + 1, value: msg.value}));
    }

    /* Terminate the contract so the tenant can’t pay rent anymore,
    and the contract is terminated */
    function terminateContract() external onlyLandlord {
        emit ContractTerminated();
        payable(landlord).transfer(address(this).balance);
        /* If there is any value on the contract send it to the landlord*/
        state = State.Terminated;
    }
}
