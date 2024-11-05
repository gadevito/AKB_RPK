pragma solidity >=0.4.22 <0.9.0;

contract EnergyTrading {
    address public owner;

    struct EnergyTransaction {
        address buyer;
        address seller;
        uint256 energyQuantity;
        uint256 price;
        bool executed;
    }

    mapping(uint256 => EnergyTransaction) public transactions;
    uint256 public transactionCount;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyParticipant(uint256 transactionId) {
        require(
            msg.sender == transactions[transactionId].buyer || msg.sender == transactions[transactionId].seller,
            "Only participants can perform this action"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function placeBuyOrder(address _seller, uint256 _energyQuantity, uint256 _price) public {
        transactions[transactionCount] = EnergyTransaction({
            buyer: msg.sender,
            seller: _seller,
            energyQuantity: _energyQuantity,
            price: _price,
            executed: false
        });
        transactionCount++;
    }

    function executeTransaction(uint256 transactionId) public onlyParticipant(transactionId) {
        EnergyTransaction storage transaction = transactions[transactionId];
        require(!transaction.executed, "Transaction already executed");
        require(transaction.buyer != address(0) && transaction.seller != address(0), "Invalid transaction participants");

        uint256 totalPrice = transaction.energyQuantity * transaction.price;
        require(address(this).balance >= totalPrice, "Insufficient contract balance");

        transaction.executed = true;
        payable(transaction.seller).transfer(totalPrice);
    }

    function deposit() public payable onlyOwner {}

    function withdraw(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient contract balance");
        payable(owner).transfer(amount);
    }

    function getTransaction(uint256 transactionId) public view returns (address, address, uint256, uint256, bool) {
        EnergyTransaction memory transaction = transactions[transactionId];
        return (transaction.buyer, transaction.seller, transaction.energyQuantity, transaction.price, transaction.executed);
    }
}