// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VariableInterestLoan {
    address public borrower;
    uint public loanAmount;
    uint public interestRate;
    uint public loanTerm;
    uint public totalInterest;
    uint public balance;
    bool public paid;

    constructor(
        address _borrower,
        uint _loanAmount,
        uint _interestRate,
        uint _loanTerm
    ) {
        borrower = _borrower;
        loanAmount = _loanAmount;
        interestRate = _interestRate;
        loanTerm = _loanTerm;
        totalInterest = 0;
        balance = _loanAmount;
        paid = false;
    }

    function calculateInterest(
        uint benchmarkInterestRate,
        uint creditScore
    ) private pure returns (uint) {
        uint riskPremium = 0;
        if (creditScore < 500) {
            riskPremium = 5;
        } else if (creditScore < 700) {
            riskPremium = 3;
        }
        uint calculatedInterest = benchmarkInterestRate + riskPremium;
        return calculatedInterest;
    }

    function makePayment() public payable {
        require(msg.sender == borrower, "Only borrower can make payments");
        require(!paid, "Loan has already been paid in full");
        require(msg.value <= balance, "Payment exceeds outstanding balance");
        balance -= msg.value;
        if (balance == 0) {
            paid = true;
        }
        uint monthlyInterest = calculateInterest(interestRate, 650);
        // the following computation does not handle approximation problems: a possible solution should be to use decimals to avoid losing precision
        uint monthlyPayment = (loanAmount * monthlyInterest) /
            (1 - (1 / (1 + monthlyInterest) ** loanTerm));
        totalInterest += monthlyInterest;
        require(
            msg.value >= monthlyPayment,
            "Payment is less than monthly amount"
        );
    }
}
