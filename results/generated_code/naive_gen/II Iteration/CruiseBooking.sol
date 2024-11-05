pragma solidity >=0.4.22 <0.9.0;

contract CruiseBooking {
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

    mapping(uint256 => Cruise) public cruises;
    mapping(uint256 => Booking) public bookings;
    mapping(address => uint256[]) public userBookings;
    mapping(address => bool) public admins;

    uint256 public nextCruiseId;
    uint256 public nextBookingId;

    event CruiseAdded(uint256 cruiseId, string name, uint256 capacity, uint256 price, uint256 reservationExpiry);
    event CruisePriceUpdated(uint256 cruiseId, uint256 newPrice);
    event BookingMade(uint256 bookingId, uint256 cruiseId, address user);
    event BookingCancelled(uint256 bookingId, uint256 cruiseId, address user);
    event BookingExtended(uint256 bookingId, uint256 newReservationExpiry);

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admins can perform this action");
        _;
    }

    constructor() {
        admins[msg.sender] = true;
    }

    function addAdmin(address admin) external onlyAdmin {
        admins[admin] = true;
    }

    function removeAdmin(address admin) external onlyAdmin {
        admins[admin] = false;
    }

    function addCruise(string memory name, uint256 capacity, uint256 price, uint256 reservationExpiry) external onlyAdmin {
        cruises[nextCruiseId] = Cruise(name, capacity, price, reservationExpiry, 0);
        emit CruiseAdded(nextCruiseId, name, capacity, price, reservationExpiry);
        nextCruiseId++;
    }

    function updateCruisePrice(uint256 cruiseId, uint256 newPrice) external onlyAdmin {
        cruises[cruiseId].price = newPrice;
        emit CruisePriceUpdated(cruiseId, newPrice);
    }

    function bookCruise(uint256 cruiseId) external payable {
        Cruise storage cruise = cruises[cruiseId];
        require(msg.value == cruise.price, "Incorrect payment amount");
        require(cruise.bookingCount < cruise.capacity, "Cruise is fully booked");

        bookings[nextBookingId] = Booking(cruiseId, msg.sender, block.timestamp, cruise.reservationExpiry);
        userBookings[msg.sender].push(nextBookingId);
        cruise.bookingCount++;

        emit BookingMade(nextBookingId, cruiseId, msg.sender);
        nextBookingId++;
    }

    function cancelBooking(uint256 bookingId) external {
        Booking storage booking = bookings[bookingId];
        require(booking.user == msg.sender, "Only the owner can cancel the booking");
        require(block.timestamp < booking.reservationExpiry, "Booking has already expired");

        Cruise storage cruise = cruises[booking.cruiseId];
        cruise.bookingCount--;

        payable(msg.sender).transfer(cruise.price);

        emit BookingCancelled(bookingId, booking.cruiseId, msg.sender);

        delete bookings[bookingId];
    }

    function extendBooking(uint256 bookingId, uint256 additionalTime) external {
        Booking storage booking = bookings[bookingId];
        require(booking.user == msg.sender, "Only the owner can extend the booking");

        booking.reservationExpiry += additionalTime;

        emit BookingExtended(bookingId, booking.reservationExpiry);
    }

    function getCruiseDetails(uint256 cruiseId) external view returns (string memory, uint256, uint256, uint256, uint256) {
        Cruise storage cruise = cruises[cruiseId];
        return (cruise.name, cruise.capacity, cruise.price, cruise.reservationExpiry, cruise.bookingCount);
    }

    function getUserBookings() external view returns (uint256[] memory) {
        return userBookings[msg.sender];
    }
}