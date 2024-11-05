pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract CruiseBooking is AccessControl {
    uint256 public cruiseCounter;
    uint256 public bookingCounter;
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

    mapping(uint256 => Cruise) public cruises;
    mapping(uint256 => Booking) public bookings;
    mapping(address => uint256[]) public userBookings;

    event CruiseAdded(uint256 cruiseId, string name, uint256 capacity, uint256 price, uint256 reservationExpiry);
    event CruisePriceUpdated(uint256 cruiseId, uint256 newPrice);
    event BookingMade(uint256 bookingId, uint256 cruiseId, address user);
    event BookingCancelled(uint256 bookingId, uint256 cruiseId, address user);
    event BookingExtended(uint256 bookingId, uint256 newExpiry);
    event AdminAdded(address newAdmin);
    event AdminRemoved(address account);

    modifier onlyAdmin() {
        require(hasRole(CRUISE_ADMIN, msg.sender), "Caller is not an admin");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CRUISE_ADMIN, msg.sender);
    }

function addCruise(string memory name, uint256 capacity, uint256 price, uint256 reservationExpiry) public onlyAdmin {
    require(capacity > 0, "Capacity must be greater than 0");
    require(price > 0, "Price must be greater than 0");
    require(reservationExpiry > block.timestamp, "Reservation expiry must be in the future");

    cruiseCounter = cruiseCounter + 1;
    uint256 newCruiseId = cruiseCounter;

    Cruise storage newCruise = cruises[newCruiseId];
    newCruise.name = name;
    newCruise.capacity = capacity;
    newCruise.price = price;
    newCruise.reservationExpiry = reservationExpiry;

    emit CruiseAdded(newCruiseId, name, capacity, price, reservationExpiry);
}


function updateCruisePrice(uint256 cruiseId, uint256 newPrice) external onlyAdmin {
    // Check if the cruise with the given cruiseId exists
    Cruise storage cruise = cruises[cruiseId];
    require(bytes(cruise.name).length != 0, "Cruise does not exist");

    // Update the price of the specified cruise to newPrice
    cruise.price = newPrice;

    // Emit the CruisePriceUpdated event with the cruiseId and newPrice
    emit CruisePriceUpdated(cruiseId, newPrice);
}


function bookCruise(uint256 cruiseId) external payable {
    // Check if the cruise with the given cruiseId exists
    Cruise storage cruise = cruises[cruiseId];
    require(bytes(cruise.name).length != 0, "Cruise does not exist");

    // Ensure the user sends the exact amount required for booking
    require(msg.value == cruise.price, "Incorrect booking amount");

    // Ensure the cruise capacity is not full
    require(cruise.bookingCount < cruise.capacity, "Cruise is fully booked");

    // Increment the bookingCounter to generate a unique booking ID
    bookingCounter = bookingCounter + 1;
    uint256 bookingId = bookingCounter;

    // Record the booking details
    Booking storage newBooking = bookings[bookingId];
    newBooking.cruiseId = cruiseId;
    newBooking.user = msg.sender;
    newBooking.timestamp = block.timestamp;
    newBooking.reservationExpiry = cruise.reservationExpiry;

    // Update the cruise's booking count
    cruise.bookingCount = cruise.bookingCount + 1;

    // Add the booking ID to the user's list of bookings
    userBookings[msg.sender].push(bookingId);

    // Emit the BookingMade event
    emit BookingMade(bookingId, cruiseId, msg.sender);
}


function cancelBooking(uint256 bookingId) external {
    // Retrieve the booking details using bookingId
    Booking storage booking = bookings[bookingId];

    // Ensure the booking exists
    require(booking.user != address(0), "Booking does not exist");

    // Ensure the caller is the owner of the booking
    require(booking.user == msg.sender, "Caller is not the owner of the booking");

    // Ensure the booking has not expired
    require(block.timestamp < booking.reservationExpiry, "Booking has expired");

    // Refund the user the booking amount
    uint256 refundAmount = cruises[booking.cruiseId].price;
    (bool success,) = payable(booking.user).call{value: refundAmount}("");
    require(success, "Refund failed");

    // Update the cruise's booking count
    uint256 cruiseId = booking.cruiseId;
    Cruise storage cruise = cruises[cruiseId];
    cruise.bookingCount = cruise.bookingCount - 1;

    // Remove the booking from the user's list of bookings
    uint256[] storage userBookingList = userBookings[msg.sender];
    for (uint256 i = 0; i < userBookingList.length; i++) {
        if (userBookingList[i] == bookingId) {
            userBookingList[i] = userBookingList[userBookingList.length - 1];
            userBookingList.pop();
            break;
        }
    }

    // Reset the booking details
    booking.cruiseId = 0;
    booking.user = address(0);
    booking.reservationExpiry = 0;

    // Emit the BookingCancelled event
    emit BookingCancelled(bookingId, cruiseId, msg.sender);
}


function extendBooking(uint256 bookingId, uint256 additionalTime) public {
    // Retrieve the booking details using bookingId
    Booking storage booking = bookings[bookingId];

    // Ensure the caller is the owner of the booking
    require(booking.user == msg.sender, "Caller is not the owner of the booking");

    // Ensure the booking has not expired
    require(block.timestamp <= booking.reservationExpiry, "Booking has already expired");

    // Calculate the new reservation expiry by adding additionalTime to the current reservation expiry
    uint256 newExpiry = booking.reservationExpiry + additionalTime;

    // Update the booking's reservation expiry with the new expiry timestamp
    booking.reservationExpiry = newExpiry;

    // Emit the BookingExtended event with bookingId and the new reservation expiry timestamp
    emit BookingExtended(bookingId, newExpiry);
}


function getCruiseDetails(uint256 cruiseId) public view returns (string memory name, uint256 capacity, uint256 price, uint256 reservationExpiry) {
    // Check if the cruise exists
    require(bytes(cruises[cruiseId].name).length > 0, "Cruise does not exist");

    // Retrieve the cruise details
    Cruise storage cruise = cruises[cruiseId];
    string memory cruiseName = cruise.name;
    uint256 cruiseCapacity = cruise.capacity;
    uint256 cruisePrice = cruise.price;
    uint256 cruiseReservationExpiry = cruise.reservationExpiry;

    // Return the cruise details
    return (cruiseName, cruiseCapacity, cruisePrice, cruiseReservationExpiry);
}


function getUserBookings() public view returns (uint256[] memory) {
    return userBookings[msg.sender];
}


function addAdmin(address newAdmin) external onlyAdmin {
    require(!hasRole(CRUISE_ADMIN, newAdmin), "Address is already an admin");

    grantRole(CRUISE_ADMIN, newAdmin);

    emit AdminAdded(newAdmin);
}


function removeAdmin(address account) external onlyAdmin {
    require(hasRole(CRUISE_ADMIN, account), "Account is not an admin");

    revokeRole(CRUISE_ADMIN, account);

    emit AdminRemoved(account);
}


}