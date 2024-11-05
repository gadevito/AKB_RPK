// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./AccessControl.sol";

contract CruiseBooking is AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant CRUISE_ADMIN = keccak256("CRUISE_ADMIN");

    struct Cruise {
        uint256 id;
        string name;
        uint256 capacity;
        uint256 booked;
        uint256 price;
        uint256 reservationExpiry;
    }

    struct Booking {
        uint256 cruiseId;
        address user;
        uint256 timestamp;
        uint256 reservationExpiry;
    }

    Counters.Counter private _nextCruiseId;
    Counters.Counter private _nextBookingId;

    mapping(uint256 => Cruise) public cruises;
    mapping(uint256 => Booking) public bookings;
    mapping(address => uint256[]) public userBookings;

    event CruiseAdded(uint256 cruiseId, string name, uint256 capacity, uint256 price, uint256 reservationExpiry);
    event CruisePriceUpdated(uint256 cruiseId, uint256 newPrice);
    event BookingMade(uint256 bookingId, uint256 cruiseId, address user);
    event BookingCancelled(uint256 bookingId, uint256 cruiseId, address user);
    event BookingExtended(uint256 bookingId, uint256 newExpiry);

    constructor(address adminAddress) {
        _setupRole(CRUISE_ADMIN, adminAddress);
    }

    function addCruise(string memory _name, uint256 _capacity, uint256 _price, uint256 _reservationExpiry) public onlyRole(CRUISE_ADMIN) {
        uint256 cruiseId = _nextCruiseId.current();
        _nextCruiseId.increment();

        Cruise memory newCruise = Cruise({
            id: cruiseId,
            name: _name,
            capacity: _capacity,
            booked: 0,
            price: _price,
            reservationExpiry: _reservationExpiry
        });

        cruises[cruiseId] = newCruise;
        emit CruiseAdded(cruiseId, _name, _capacity, _price, _reservationExpiry);
    }

    function updateCruisePrice(uint256 _cruiseId, uint256 _newPrice) public onlyRole(CRUISE_ADMIN) {
        require(cruiseExists(_cruiseId), "Cruise does not exist");
        cruises[_cruiseId].price = _newPrice;
        emit CruisePriceUpdated(_cruiseId, _newPrice);
    }

    function bookCruise(uint256 _cruiseId) public payable {
        require(cruiseExists(_cruiseId), "Cruise does not exist");
        require(cruises[_cruiseId].capacity > cruises[_cruiseId].booked, "No available spots");
        require(msg.value == cruises[_cruiseId].price, "Incorrect payment amount");

        cruises[_cruiseId].booked++;
        uint256 bookingId = _nextBookingId.current();
        _nextBookingId.increment();

        Booking memory newBooking = Booking({
            cruiseId: _cruiseId,
            user: msg.sender,
            timestamp: block.timestamp,
            reservationExpiry: block.timestamp + cruises[_cruiseId].reservationExpiry
        });

        bookings[bookingId] = newBooking;
        userBookings[msg.sender].push(bookingId);

        emit BookingMade(bookingId, _cruiseId, msg.sender);
    }

    function cancelBooking(uint256 _bookingId) public {
        require(bookingExists(_bookingId), "Booking does not exist");
        Booking memory booking = bookings[_bookingId];
        require(booking.user == msg.sender, "Not the owner of this booking");

        require(block.timestamp <= booking.reservationExpiry, "Booking has expired");

        cruises[booking.cruiseId].booked--;
        delete bookings[_bookingId];

        payable(booking.user).transfer(cruises[booking.cruiseId].price);

        uint256[] storage userBookingList = userBookings[msg.sender];
        for (uint256 i = 0; i < userBookingList.length; i++) {
            if (userBookingList[i] == _bookingId) {
                userBookingList[i] = userBookingList[userBookingList.length - 1];
                userBookingList.pop();
                break;
            }
        }

        emit BookingCancelled(_bookingId, booking.cruiseId, msg.sender);
    }

    function extendBooking(uint256 _bookingId, uint256 _additionalTime) public {
        require(bookingExists(_bookingId), "Booking does not exist");
        Booking storage booking = bookings[_bookingId];
        require(booking.user == msg.sender, "Not the owner of this booking");

        require(block.timestamp <= booking.reservationExpiry, "Booking has expired");

        booking.reservationExpiry += _additionalTime;
        emit BookingExtended(_bookingId, booking.reservationExpiry);
    }

    function getCruiseDetails(uint256 _cruiseId) public view returns (Cruise memory) {
        require(cruiseExists(_cruiseId), "Cruise does not exist");
        return cruises[_cruiseId];
    }

    function getUserBookings() public view returns (Booking[] memory) {
        uint256[] memory bookingIds = userBookings[msg.sender];
        Booking[] memory userBookingList = new Booking[](bookingIds.length);

        for (uint256 i = 0; i < bookingIds.length; i++) {
            userBookingList[i] = bookings[bookingIds[i]];
        }

        return userBookingList;
    }

    function cruiseExists(uint256 _cruiseId) internal view returns (bool) {
        return cruises[_cruiseId].id == _cruiseId;
    }

    function bookingExists(uint256 _bookingId) internal view returns (bool) {
        return bookings[_bookingId].user != address(0);
    }

    function addAdmin(address account) public onlyRole(CRUISE_ADMIN) {
        grantRole(CRUISE_ADMIN, account);
    }

    function removeAdmin(address account) public onlyRole(CRUISE_ADMIN) {
        revokeRole(CRUISE_ADMIN, account);
    }
}
