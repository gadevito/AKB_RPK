pragma solidity >=0.4.22 <0.9.0;

contract VariableInterestLoan {
    address public borrower;
    uint256 public loanAmount;
    uint256 public interestRate;
    uint256 public loanTerm;
    uint256 public totalInterest;
    uint256 public balance;
    bool public paid;

    constructor(address _borrower, uint256 _loanAmount, uint256 _interestRate, uint256 _loanTerm) {
        borrower = _borrower;
        loanAmount = _loanAmount;
        interestRate = _interestRate;
        loanTerm = _loanTerm;
        totalInterest = 0;
        balance = _loanAmount;
        paid = false;
    }

    function calculateInterest(uint256 creditScore) public view returns (uint256) {
        uint256 riskPremium;
        if (creditScore < 500) {
            riskPremium = 5;
        } else if (creditScore >= 500 && creditScore < 700) {
            riskPremium = 3;
        } else if (creditScore >= 700) {
            riskPremium = 0;
        }
        return interestRate + riskPremium;
    }

    function calculateMonthlyPayment() public view returns (uint256) {
        require(loanTerm > 0, "Loan term must be greater than zero");
        uint256 monthlyInterestRate = (interestRate * 1e18) / 12 / 100;
        uint256 numerator = loanAmount * monthlyInterestRate / 1e18;
        uint256 denominator = 1e18 - (1e18 * 1e18 / ((1e18 + monthlyInterestRate) ** loanTerm));
        return numerator * 1e18 / denominator;
    }

    function makePayment(uint256 paymentAmount) public {
        require(msg.sender == borrower, "Only borrower can make payments");
        require(!paid, "Loan has already been paid in full");

        uint256 monthlyInterestRate = (interestRate * 1e18) / 12 / 100;
        uint256 interestForThisPayment = balance * monthlyInterestRate / 1e18;
        totalInterest += interestForThisPayment;

        require(paymentAmount >= interestForThisPayment, "Payment amount must cover at least the interest");

        uint256 principalPayment = paymentAmount - interestForThisPayment;
        balance = balance > principalPayment ? balance - principalPayment : 0;

        if (balance == 0) {
            paid = true;
        }

        emit PaymentMade(msg.sender, paymentAmount, balance);
    }

    event PaymentMade(address indexed payer, uint256 amount, uint256 remainingBalance);
}