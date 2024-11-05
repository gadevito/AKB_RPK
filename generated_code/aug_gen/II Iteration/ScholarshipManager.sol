pragma solidity >=0.4.22 <0.9.0;

import './hardhat/AlumniStore.sol';
import './hardhat/OpenCertsStore.sol';
import './hardhat/TokenContract.sol';

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

contract ScholarshipManager {
    using SafeMath for uint256;

    address public owner;
    OpenCertsStore public openCertsStore;
    AlumniStore public alumniStore;
    TokenContract public tokenContract;
    uint256 public bitDegreeFeePercent = 3;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FundsUnlocked(address indexed student, uint256 amount, uint256 bitDegreeFee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor(address _openCertsStore, address _alumniStore, address _tokenContract) public {
        owner = msg.sender;
        openCertsStore = OpenCertsStore(_openCertsStore);
        alumniStore = AlumniStore(_alumniStore);
        tokenContract = TokenContract(_tokenContract);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    receive() external payable {
        // Fallback function to accept Ether payments
    }

    function checkScholarship(bytes32 _hash) public view returns (address) {
        if (!openCertsStore.isIssued(_hash)) {
            return address(0);
        }
        return alumniStore.getAlumniAddress(_hash);
    }

    function unlockFunds(bytes32 _hash) public returns (bool) {
        if (!openCertsStore.isIssued(_hash)) {
            return false;
        }

        address student = alumniStore.getAlumniAddress(_hash);
        uint256 balance = tokenContract.balanceOf(address(this));
        uint256 bitDegreeFee = balance.mul(bitDegreeFeePercent).div(100);
        uint256 studentAmount = balance.sub(bitDegreeFee);

        require(balance >= studentAmount.add(bitDegreeFee), "Insufficient contract balance");

        if (!tokenContract.transfer(student, studentAmount)) {
            return false;
        }
        if (!tokenContract.transfer(owner, bitDegreeFee)) {
            return false;
        }

        emit FundsUnlocked(student, studentAmount, bitDegreeFee);
        return true;
    }

    function withdrawAllFunds() public onlyOwner {
        uint256 balance = tokenContract.balanceOf(address(this));
        require(balance > 0, "No funds to withdraw");
        require(tokenContract.transfer(owner, balance), "Transfer failed");
    }

    function destroyContract() public onlyOwner {
        uint256 tokenBalance = tokenContract.balanceOf(address(this));
        if (tokenBalance > 0) {
            require(tokenContract.transfer(owner, tokenBalance), "Token transfer failed");
        }
        selfdestruct(payable(owner));
    }
}