// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MicroLoan {
    struct Loan {
        address borrower;
        uint amount;
        uint interestRate;
        bool funded;
    }

    struct Deposit {
        uint amount;
        uint interestRate;
        uint startTime;
    }

    Loan[] public loans;
    mapping(address => uint[]) public borrowerLoans;
    mapping(address => Deposit) public borrowerDeposits;
    mapping(address => uint) public lenderBalances;

    event LoanRequested(uint indexed loanId, address indexed borrower, uint amount, uint interestRate);
    event LoanFunded(uint indexed loanId, address indexed lender, uint amount);
    event DepositMade(address indexed borrower, uint amount, uint interestRate, uint startTime);
    event InterestWithdrawn(address indexed borrower, uint amount);

    function requestLoan(uint _amount, uint _interestRate) external {
        require(_interestRate >= 5, "Interest rate must be 5% or higher");
        
        loans.push(Loan(msg.sender, _amount, _interestRate, false));
        uint loanId = loans.length - 1;
        borrowerLoans[msg.sender].push(loanId);
        emit LoanRequested(loanId, msg.sender, _amount, _interestRate);
    }


    function fundLoan(uint _loanId) external payable {
        Loan storage loan = loans[_loanId];
        require(!loan.funded, "Loan already funded");
        require(msg.value >= loan.amount, "Insufficient funds");
        loan.funded = true;
        lenderBalances[msg.sender] += msg.value;
        payable(loan.borrower).transfer(msg.value);
        emit LoanFunded(_loanId, msg.sender, msg.value);
    }

    function makeDeposit(uint _interestRate) external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        require(borrowerDeposits[msg.sender].amount == 0, "Deposit already exists");
        borrowerDeposits[msg.sender] = Deposit(msg.value, _interestRate, block.timestamp);
        emit DepositMade(msg.sender, msg.value, _interestRate, block.timestamp);
    }

    function withdrawInterest() external {
        Deposit storage deposit = borrowerDeposits[msg.sender];
        require(deposit.amount > 0, "No deposit exists");
        
        uint elapsedTime = block.timestamp - deposit.startTime;
        uint elapsedMonths = elapsedTime / (30 days); // Calculate the months

        uint interest = (deposit.amount * deposit.interestRate * elapsedMonths) / 100;
        require(interest > 0, "No interest accrued");
        
        payable(msg.sender).transfer(interest);
        emit InterestWithdrawn(msg.sender, interest);
    }

    function getLoansByBorrower(address _borrower) external view returns (uint[] memory) {
        return borrowerLoans[_borrower];
    }

    function getLoan(uint _loanId) external view returns (address, uint, uint, bool) {
        Loan storage loan = loans[_loanId];
        return (loan.borrower, loan.amount, loan.interestRate, loan.funded);
    }

    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    }
}