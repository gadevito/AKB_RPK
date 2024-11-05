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

    mapping(address => uint256) public balances;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyAuthorized(address _address) {
        require(_address == owner || _address == msg.sender, "Not authorized");
        _;
    }

    event BuyOrderPlaced(uint256 transactionId, address buyer, uint256 energyQuantity, uint256 price);
    event TransactionExecuted(uint256 transactionId, address buyer, address seller, uint256 energyQuantity, uint256 totalPrice);
    event Deposit(address indexed owner, uint256 amount);
    event Withdrawal(address indexed owner, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function placeBuyOrder(address _seller, uint256 _energyQuantity, uint256 _price) public {
        transactionCount++;
        transactions[transactionCount] = EnergyTransaction({
            buyer: msg.sender,
            seller: _seller,
            energyQuantity: _energyQuantity,
            price: _price,
            executed: false
        });

        emit BuyOrderPlaced(transactionCount, msg.sender, _energyQuantity, _price);
    }

    function executeTransaction(uint256 _transactionId) public {
        EnergyTransaction storage transaction = transactions[_transactionId];
        require(transaction.buyer != address(0) && transaction.seller != address(0), "Invalid transaction participants");
        require(!transaction.executed, "Transaction already executed");
        require(msg.sender == transaction.seller || msg.sender == owner, "Not authorized");

        uint256 totalPrice = transaction.energyQuantity * transaction.price;
        require(balances[transaction.buyer] >= totalPrice, "Insufficient buyer balance to execute transaction");

        balances[transaction.buyer] -= totalPrice;
        balances[transaction.seller] += totalPrice;

        transaction.executed = true;

        emit TransactionExecuted(_transactionId, transaction.buyer, transaction.seller, transaction.energyQuantity, totalPrice);
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Insufficient contract balance");
        payable(owner).transfer(_amount);
        emit Withdrawal(owner, _amount);
    }
}