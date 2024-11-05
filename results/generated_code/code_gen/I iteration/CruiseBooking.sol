pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CruiseBooking is AccessControl {
    using SafeMath for uint256;

    uint256 public cruiseCounter;
    uint256 public bookingCounter;
    bytes32 public constant CRUISE_ADMIN = keccak256("CRUISE_ADMIN");

    struct Cruise {
        string name;
        uint256 capacity;
        uint256 price;
        uint256 reservationExpiry;
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
    require(bytes(name).length > 0, "Cruise name cannot be empty");
    require(capacity > 0, "Cruise capacity must be greater than 0");
    require(price > 0, "Cruise price must be greater than 0");
    require(reservationExpiry > block.timestamp, "Reservation expiry must be a future timestamp");

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

    // Update the price of the specified cruise
    cruise.price = newPrice;

    // Emit the CruisePriceUpdated event
    emit CruisePriceUpdated(cruiseId, newPrice);
}


function bookCruise(uint256 cruiseId) external payable {
    // Check if the cruise with cruiseId exists
    Cruise storage cruise = cruises[cruiseId];
    require(bytes(cruise.name).length != 0, "Cruise does not exist");

    // Verify that the sent value matches the price of the cruise
    require(msg.value == cruise.price, "Incorrect payment amount");

    // Ensure the cruise has available capacity
    require(cruise.capacity > 0, "Cruise is fully booked");

    // Increment the bookingCounter to generate a unique booking ID
    bookingCounter = bookingCounter + 1;
    uint256 bookingId = bookingCounter;

    // Record the booking details
    Booking storage newBooking = bookings[bookingId];
    newBooking.cruiseId = cruiseId;
    newBooking.user = msg.sender;
    newBooking.timestamp = block.timestamp;
    newBooking.reservationExpiry = cruise.reservationExpiry;
    // newBooking.amountPaid = msg.value; // This line is removed as amountPaid is not a member of Booking

    // Update the cruise's booking count
    cruise.capacity = cruise.capacity - 1;

    // Add the booking ID to the user's list of bookings
    userBookings[msg.sender].push(bookingId);

    // Emit the BookingMade event
    emit BookingMade(bookingId, cruiseId, msg.sender);
}


function cancelBooking(uint256 bookingId) external {
    // Retrieve the booking details using bookingId
    Booking storage booking = bookings[bookingId];

    // Check if the booking exists
    require(booking.user != address(0), "Booking does not exist");

    // Check if the caller is the owner of the booking
    require(booking.user == msg.sender, "Caller is not the owner of the booking");

    // Check if the booking has not expired
    require(block.timestamp < booking.reservationExpiry, "Booking has expired");

    // Refund the user the booking amount
    uint256 refundAmount = cruises[booking.cruiseId].price;
    (bool success,) = payable(booking.user).call{value: refundAmount}("");
    require(success, "Refund failed");

    // Update the cruise's booking count
    uint256 cruiseId = booking.cruiseId;
    Cruise storage cruise = cruises[cruiseId];
    cruise.capacity = cruise.capacity + 1;

    // Remove the booking from the user's list of bookings
    uint256[] storage userBookingList = userBookings[msg.sender];
    for (uint256 i = 0; i < userBookingList.length; i = i + 1) {
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
    require(additionalTime > 0, "Additional time must be greater than zero");

    Booking storage booking = bookings[bookingId];
    address bookingOwner = booking.user;
    uint256 currentExpiry = booking.reservationExpiry;

    require(msg.sender == bookingOwner, "Caller is not the owner of the booking");
    require(block.timestamp < currentExpiry, "Booking has already expired");

    uint256 newExpiry = currentExpiry + additionalTime;
    booking.reservationExpiry = newExpiry;

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
    require(newAdmin != address(0), "New admin address cannot be zero address");
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