pragma solidity >=0.4.22 <0.9.0;

contract VariableInterestLoan {
    address public borrower;
    uint256 public loanAmount;
    uint256 public interestRate;
    uint256 public loanTerm;
    uint256 public totalInterest;
    uint256 public balance;
    bool public paid;

    constructor(address _borrower, uint256 _loanAmount, uint256 _interestRate, uint256 _loanTerm) public {
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

    function calculateMonthlyPayment() public view returns (uint256) {
        uint256 monthlyInterestRate = (interestRate * 1e18) / 12 / 100;
        uint256 numerator = loanAmount * monthlyInterestRate / 1e18 * ((1e18 + monthlyInterestRate) ** loanTerm);
        uint256 denominator = ((1e18 + monthlyInterestRate) ** loanTerm) - 1e18;
        return numerator / denominator;
    }

    function makePayment(uint256 paymentAmount) public {
        require(msg.sender == borrower, "Only borrower can make payments");
        require(!paid, "Loan has already been paid in full");
        require(paymentAmount <= balance, "Payment exceeds outstanding balance");

        uint256 monthlyInterestRate = (interestRate * 1e18) / 12 / 100;
        uint256 interest = balance * monthlyInterestRate / 1e18;

        if (paymentAmount < interest) {
            totalInterest += interest;
            balance += interest - paymentAmount;
        } else {
            uint256 principalPayment = paymentAmount - interest;
            balance = balance > principalPayment ? balance - principalPayment : 0;
            totalInterest += interest;
        }

        if (balance == 0) {
            paid = true;
        }
    }
}