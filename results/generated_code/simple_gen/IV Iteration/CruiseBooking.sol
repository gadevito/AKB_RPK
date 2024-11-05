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

    function addAdmin(address admin) public onlyAdmin {
        admins[admin] = true;
    }

    function removeAdmin(address admin) public onlyAdmin {
        admins[admin] = false;
    }

    function addCruise(string memory name, uint256 capacity, uint256 price, uint256 reservationExpiry) public onlyAdmin {
        cruiseCount++;
        cruises[cruiseCount] = Cruise(name, capacity, price, reservationExpiry, 0);
        emit CruiseAdded(cruiseCount, name, capacity, price, reservationExpiry);
    }

    function updateCruisePrice(uint256 cruiseId, uint256 newPrice) public onlyAdmin {
        require(cruiseId > 0 && cruiseId <= cruiseCount, "Invalid cruise ID");
        cruises[cruiseId].price = newPrice;
        emit CruisePriceUpdated(cruiseId, newPrice);
    }

    function bookCruise(uint256 cruiseId) public payable {
        require(cruiseId > 0 && cruiseId <= cruiseCount, "Invalid cruise ID");
        Cruise storage cruise = cruises[cruiseId];
        require(msg.value == cruise.price, "Incorrect payment amount");
        require(cruise.bookingCount < cruise.capacity, "Cruise is fully booked");

        bookingCount++;
        bookings[bookingCount] = Booking(cruiseId, msg.sender, block.timestamp, cruise.reservationExpiry);
        userBookings[msg.sender].push(bookingCount);
        cruise.bookingCount++;

        emit BookingMade(bookingCount, cruiseId, msg.sender);
    }

    function cancelBooking(uint256 bookingId) public {
        require(bookingId > 0 && bookingId <= bookingCount, "Invalid booking ID");
        Booking storage booking = bookings[bookingId];
        require(booking.user == msg.sender, "Only the owner can cancel the booking");
        require(block.timestamp < booking.reservationExpiry, "Booking has expired");

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

    function extendBooking(uint256 bookingId, uint256 additionalTime) public {
        require(bookingId > 0 && bookingId <= bookingCount, "Invalid booking ID");
        Booking storage booking = bookings[bookingId];
        require(booking.user == msg.sender, "Only the owner can extend the booking");

        booking.reservationExpiry += additionalTime;
        emit BookingExtended(bookingId, booking.reservationExpiry);
    }

    function getCruiseDetails(uint256 cruiseId) public view returns (string memory, uint256, uint256, uint256, uint256) {
        require(cruiseId > 0 && cruiseId <= cruiseCount, "Invalid cruise ID");
        Cruise storage cruise = cruises[cruiseId];
        return (cruise.name, cruise.capacity, cruise.price, cruise.reservationExpiry, cruise.bookingCount);
    }

    function getUserBookings() public view returns (uint256[] memory) {
        return userBookings[msg.sender];
    }
}