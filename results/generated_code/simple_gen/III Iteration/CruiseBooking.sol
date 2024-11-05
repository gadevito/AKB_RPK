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

    uint256 public cruiseCount;
    uint256 public bookingCount;

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

    function addAdmin(address account) external onlyAdmin {
        admins[account] = true;
    }

    function removeAdmin(address account) external onlyAdmin {
        admins[account] = false;
    }

    function addCruise(string memory name, uint256 capacity, uint256 price, uint256 reservationExpiry) external onlyAdmin {
        cruiseCount++;
        cruises[cruiseCount] = Cruise(name, capacity, price, reservationExpiry, 0);
        emit CruiseAdded(cruiseCount, name, capacity, price, reservationExpiry);
    }

    function updateCruisePrice(uint256 cruiseId, uint256 newPrice) external onlyAdmin {
        require(cruises[cruiseId].capacity > 0, "Cruise does not exist");
        cruises[cruiseId].price = newPrice;
        emit CruisePriceUpdated(cruiseId, newPrice);
    }

    function bookCruise(uint256 cruiseId) external payable {
        require(cruises[cruiseId].capacity > 0, "Cruise does not exist");
        require(msg.value == cruises[cruiseId].price, "Incorrect payment amount");
        require(cruises[cruiseId].bookingCount < cruises[cruiseId].capacity, "Cruise is fully booked");

        bookingCount++;
        bookings[bookingCount] = Booking(cruiseId, msg.sender, block.timestamp, block.timestamp + cruises[cruiseId].reservationExpiry);
        userBookings[msg.sender].push(bookingCount);
        cruises[cruiseId].bookingCount++;

        emit BookingMade(bookingCount, cruiseId, msg.sender);
    }

    function cancelBooking(uint256 bookingId) external {
        Booking storage booking = bookings[bookingId];
        require(booking.user == msg.sender, "Only the owner can cancel the booking");
        require(block.timestamp <= booking.reservationExpiry, "Booking has expired");

        uint256 cruiseId = booking.cruiseId;
        cruises[cruiseId].bookingCount--;
        delete bookings[bookingId];

        uint256[] storage userBookingList = userBookings[msg.sender];
        for (uint256 i = 0; i < userBookingList.length; i++) {
            if (userBookingList[i] == bookingId) {
                userBookingList[i] = userBookingList[userBookingList.length - 1];
                userBookingList.pop();
                break;
            }
        }

        payable(msg.sender).transfer(cruises[cruiseId].price);
        emit BookingCancelled(bookingId, cruiseId, msg.sender);
    }

    function extendBooking(uint256 bookingId, uint256 additionalTime) external {
        Booking storage booking = bookings[bookingId];
        require(booking.user == msg.sender, "Only the owner can extend the booking");
        require(block.timestamp <= booking.reservationExpiry, "Booking has expired");

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