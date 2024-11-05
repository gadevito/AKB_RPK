pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract CruiseBooking is AccessControl {
    bytes32 public constant CRUISE_ADMIN = keccak256("CRUISE_ADMIN");

    struct Cruise {
        string name;
        uint256 capacity;
        uint256 price;
        uint256 reservationExpiry;
        uint256 bookingCount;
    }

    struct Booking {
        uint256 cruiseId;
        address user;
        uint256 timestamp;
        uint256 reservationExpiry;
    }

    uint256 private cruiseCounter;
    uint256 private bookingCounter;

    mapping(uint256 => Cruise) private cruises;
    mapping(uint256 => Booking) private bookings;
    mapping(address => uint256[]) private userBookings;

    event CruiseAdded(uint256 cruiseId, string name, uint256 capacity, uint256 price, uint256 reservationExpiry);
    event CruisePriceUpdated(uint256 cruiseId, uint256 newPrice);
    event BookingMade(uint256 bookingId, uint256 cruiseId, address user);
    event BookingCancelled(uint256 bookingId, uint256 cruiseId, address user);
    event BookingExtended(uint256 bookingId, uint256 newReservationExpiry);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CRUISE_ADMIN, msg.sender);
    }

    modifier onlyAdmin() {
        require(hasRole(CRUISE_ADMIN, msg.sender), "Caller is not a cruise admin");
        _;
    }

    function addCruise(string memory name, uint256 capacity, uint256 price, uint256 reservationExpiry) public onlyAdmin {
        cruiseCounter++;
        cruises[cruiseCounter] = Cruise(name, capacity, price, reservationExpiry, 0);
        emit CruiseAdded(cruiseCounter, name, capacity, price, reservationExpiry);
    }

    function updateCruisePrice(uint256 cruiseId, uint256 newPrice) public onlyAdmin {
        require(cruises[cruiseId].capacity > 0, "Cruise does not exist");
        cruises[cruiseId].price = newPrice;
        emit CruisePriceUpdated(cruiseId, newPrice);
    }

    function bookCruise(uint256 cruiseId) public payable {
        require(cruises[cruiseId].capacity > 0, "Cruise does not exist");
        require(msg.value == cruises[cruiseId].price, "Incorrect payment amount");
        require(cruises[cruiseId].bookingCount < cruises[cruiseId].capacity, "Cruise is fully booked");

        bookingCounter++;
        bookings[bookingCounter] = Booking(cruiseId, msg.sender, block.timestamp, block.timestamp + cruises[cruiseId].reservationExpiry);
        userBookings[msg.sender].push(bookingCounter);
        cruises[cruiseId].bookingCount++;

        emit BookingMade(bookingCounter, cruiseId, msg.sender);
    }

    function cancelBooking(uint256 bookingId) public {
        Booking storage booking = bookings[bookingId];
        require(booking.user == msg.sender, "Caller is not the owner of the booking");
        require(block.timestamp <= booking.reservationExpiry, "Booking has expired");

        uint256 cruiseId = booking.cruiseId;
        cruises[cruiseId].bookingCount--;
        delete bookings[bookingId];

        uint256[] storage userBookingList = userBookings[msg.sender];
        bool bookingFound = false;
        for (uint256 i = 0; i < userBookingList.length; i++) {
            if (userBookingList[i] == bookingId) {
                userBookingList[i] = userBookingList[userBookingList.length - 1];
                userBookingList.pop();
                bookingFound = true;
                break;
            }
        }
        require(bookingFound, "Booking ID not found in user bookings");

        payable(msg.sender).transfer(cruises[cruiseId].price);
        emit BookingCancelled(bookingId, cruiseId, msg.sender);
    }

    function extendBooking(uint256 bookingId, uint256 additionalTime) public {
        require(additionalTime > 0, "Additional time must be greater than zero");
        Booking storage booking = bookings[bookingId];
        require(booking.user == msg.sender, "Caller is not the owner of the booking");
        require(block.timestamp <= booking.reservationExpiry, "Booking has expired");

        booking.reservationExpiry += additionalTime;
        emit BookingExtended(bookingId, booking.reservationExpiry);
    }

    function getCruiseDetails(uint256 cruiseId) public view returns (string memory, uint256, uint256, uint256, uint256) {
        require(cruises[cruiseId].capacity > 0, "Cruise does not exist");
        Cruise storage cruise = cruises[cruiseId];
        return (cruise.name, cruise.capacity, cruise.price, cruise.reservationExpiry, cruise.bookingCount);
    }

    function getUserBookings() public view returns (uint256[] memory) {
        return userBookings[msg.sender];
    }

    function addAdmin(address account) public onlyAdmin {
        grantRole(CRUISE_ADMIN, account);
    }

    function removeAdmin(address account) public onlyAdmin {
        revokeRole(CRUISE_ADMIN, account);
    }
}