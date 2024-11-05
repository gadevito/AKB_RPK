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

        // Update the price of the specified cruise
        cruise.price = newPrice;

        // Emit the CruisePriceUpdated event
        emit CruisePriceUpdated(cruiseId, newPrice);
    }

    function bookCruise(uint256 cruiseId) external payable {
        // Check if the cruise with the given cruiseId exists
        Cruise storage cruise = cruises[cruiseId];
        require(bytes(cruise.name).length != 0, "Cruise does not exist");

        // Ensure the user sends the exact amount required for booking
        require(msg.value == cruise.price, "Incorrect booking amount");

        // Increment the bookingCounter to generate a unique booking ID
        bookingCounter = bookingCounter + 1;
        uint256 newBookingId = bookingCounter;

        // Record the booking details
        Booking storage newBooking = bookings[newBookingId];
        newBooking.cruiseId = cruiseId;
        newBooking.user = msg.sender;
        newBooking.timestamp = block.timestamp;
        newBooking.reservationExpiry = cruise.reservationExpiry;

        // Update the userBookings mapping to include the new booking ID for the user
        userBookings[msg.sender].push(newBookingId);

        // Emit the BookingMade event with the booking ID, cruise ID, and user address
        emit BookingMade(newBookingId, cruiseId, msg.sender);
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

        // Refund the user the amount they paid for the booking
        uint256 refundAmount = cruises[booking.cruiseId].price;
        (bool success,) = payable(booking.user).call{value: refundAmount}("");
        require(success, "Refund failed");

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
        emit BookingCancelled(bookingId, booking.cruiseId, msg.sender);
    }

    function extendBooking(uint256 bookingId, uint256 additionalTime) public {
        // Check if the booking exists
        Booking storage booking = bookings[bookingId];
        require(booking.user != address(0), "Booking does not exist");

        // Verify that the caller is the owner of the booking
        require(booking.user == msg.sender, "Caller is not the owner of the booking");

        // Ensure the booking has not expired
        require(block.timestamp < booking.reservationExpiry, "Booking has already expired");

        // Calculate the new reservation expiry
        uint256 newExpiry = booking.reservationExpiry + additionalTime;

        // Update the booking's reservation expiry
        booking.reservationExpiry = newExpiry;

        // Emit the BookingExtended event
        emit BookingExtended(bookingId, newExpiry);
    }

    function getCruiseDetails(uint256 cruiseId) public view returns (string memory name, uint256 capacity, uint256 price, uint256 reservationExpiry) {
        // Check if the cruise exists
        if (bytes(cruises[cruiseId].name).length == 0) {
            revert("Cruise does not exist");
        }

        // Retrieve cruise details
        Cruise storage cruise = cruises[cruiseId];
        name = cruise.name;
        capacity = cruise.capacity;
        price = cruise.price;
        reservationExpiry = cruise.reservationExpiry;

        return (name, capacity, price, reservationExpiry);
    }

    function getUserBookings() public view returns (uint256[] memory) {
        return userBookings[msg.sender];
    }

    function addAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid address");
        require(!hasRole(CRUISE_ADMIN, newAdmin), "Address is already an admin");

        grantRole(CRUISE_ADMIN, newAdmin);

        emit RoleGranted(CRUISE_ADMIN, newAdmin, msg.sender);
    }

    function removeAdmin(address admin) external onlyAdmin {
        require(admin != address(0), "Admin address cannot be zero");

        revokeRole(CRUISE_ADMIN, admin);

        emit RoleRevoked(CRUISE_ADMIN, admin, msg.sender);
    }
}