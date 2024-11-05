pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CruiseBooking is AccessControl {
    using Counters for Counters.Counter;

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

    Counters.Counter private _cruiseIdCounter;
    Counters.Counter private _bookingIdCounter;

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
        _cruiseIdCounter.increment();
        uint256 cruiseId = _cruiseIdCounter.current();

        cruises[cruiseId] = Cruise({
            name: name,
            capacity: capacity,
            price: price,
            reservationExpiry: reservationExpiry,
            bookingCount: 0
        });

        emit CruiseAdded(cruiseId, name, capacity, price, reservationExpiry);
    }

    function updateCruisePrice(uint256 cruiseId, uint256 newPrice) public onlyAdmin {
        require(cruises[cruiseId].capacity > 0, "Cruise does not exist");
        cruises[cruiseId].price = newPrice;
        emit CruisePriceUpdated(cruiseId, newPrice);
    }

    function bookCruise(uint256 cruiseId) public payable {
        require(cruises[cruiseId].capacity > 0, "Cruise does not exist");
        require(msg.value == cruises[cruiseId].price, "Incorrect booking amount");
        require(cruises[cruiseId].bookingCount < cruises[cruiseId].capacity, "Cruise is fully booked");

        _bookingIdCounter.increment();
        uint256 bookingId = _bookingIdCounter.current();

        bookings[bookingId] = Booking({
            cruiseId: cruiseId,
            user: msg.sender,
            timestamp: block.timestamp,
            reservationExpiry: block.timestamp + cruises[cruiseId].reservationExpiry
        });

        cruises[cruiseId].bookingCount++;
        userBookings[msg.sender].push(bookingId);

        emit BookingMade(bookingId, cruiseId, msg.sender);
    }

    function cancelBooking(uint256 bookingId) public {
        Booking storage booking = bookings[bookingId];
        require(booking.user == msg.sender, "Caller is not the owner of the booking");
        require(block.timestamp <= booking.reservationExpiry, "Booking has expired");

        uint256 cruiseId = booking.cruiseId;
        cruises[cruiseId].bookingCount--;

        delete bookings[bookingId];
        _removeUserBooking(msg.sender, bookingId);

        payable(msg.sender).transfer(cruises[cruiseId].price);

        emit BookingCancelled(bookingId, cruiseId, msg.sender);
    }

    function extendBooking(uint256 bookingId, uint256 additionalTime) public {
        Booking storage booking = bookings[bookingId];
        require(booking.user == msg.sender, "Caller is not the owner of the booking");

        booking.reservationExpiry += additionalTime;

        emit BookingExtended(bookingId, booking.reservationExpiry);
    }

    function getCruiseDetails(uint256 cruiseId) public view returns (string memory, uint256, uint256, uint256, uint256) {
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

    function _removeUserBooking(address user, uint256 bookingId) internal {
        uint256[] storage bookingsArray = userBookings[user];
        for (uint256 i = 0; i < bookingsArray.length; i++) {
            if (bookingsArray[i] == bookingId) {
                bookingsArray[i] = bookingsArray[bookingsArray.length - 1];
                bookingsArray.pop();
                break;
            }
        }
    }
}