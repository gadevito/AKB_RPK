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

    EnergyTransaction[] public transactions;

    mapping(address => uint256) public balances;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyAuthorized(address _address) {
        require(_address == msg.sender, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function placeBuyOrder(address _seller, uint256 _energyQuantity, uint256 _price) public {
        EnergyTransaction memory newTransaction = EnergyTransaction({
            buyer: msg.sender,
            seller: _seller,
            energyQuantity: _energyQuantity,
            price: _price,
            executed: false
        });

        transactions.push(newTransaction);
    }

    function executeTransaction(uint256 _transactionId) public {
        EnergyTransaction storage transaction = transactions[_transactionId];

        require(transaction.buyer == msg.sender || transaction.seller == msg.sender, "Not authorized to execute this transaction");
        require(!transaction.executed, "Transaction already executed");

        uint256 totalPrice = transaction.energyQuantity * transaction.price;

        require(balances[transaction.buyer] >= totalPrice, "Insufficient balance");

        balances[transaction.buyer] -= totalPrice;
        balances[transaction.seller] += totalPrice;

        transaction.executed = true;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function getTransaction(uint256 _transactionId) public view returns (address, address, uint256, uint256, bool) {
        EnergyTransaction memory transaction = transactions[_transactionId];
        return (transaction.buyer, transaction.seller, transaction.energyQuantity, transaction.price, transaction.executed);
    }
}