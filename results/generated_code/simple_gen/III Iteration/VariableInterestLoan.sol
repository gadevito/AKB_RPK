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
        } else if (creditScore >= 500 && creditScore <= 699) {
            riskPremium = 3;
        } else {
            riskPremium = 0;
        }
        return interestRate + riskPremium;
    }

    function calculateMonthlyPayment(uint256 creditScore) public view returns (uint256) {
        uint256 monthlyInterestRate = calculateInterest(creditScore) * 1e18 / 12 / 100;
        uint256 numerator = loanAmount * monthlyInterestRate / 1e18;
        uint256 denominator = 1e18;
        for (uint256 i = 0; i < loanTerm; i++) {
            denominator = denominator * (1e18 + monthlyInterestRate) / 1e18;
        }
        denominator = 1e18 - (1e18 * 1e18 / denominator);
        require(denominator != 0, "Denominator is zero, invalid calculation");
        return numerator * 1e18 / denominator;
    }

    function makePayment(uint256 paymentAmount) public {
        require(msg.sender == borrower, "Only borrower can make payments");
        require(!paid, "Loan has already been paid in full");
        require(paymentAmount <= balance, "Payment exceeds outstanding balance");

        uint256 monthlyInterestRate = interestRate * 1e18 / 12 / 100;
        uint256 interestPayment = balance * monthlyInterestRate / 1e18;
        uint256 principalPayment = paymentAmount > interestPayment ? paymentAmount - interestPayment : 0;

        balance -= principalPayment;
        totalInterest += interestPayment;

        if (balance == 0) {
            paid = true;
        }
    }
}