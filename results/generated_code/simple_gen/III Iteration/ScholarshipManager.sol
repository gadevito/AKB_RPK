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
        require(c / a == b, "Multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Subtraction overflow");
        uint256 c = a - b;
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
    event FundsUnlocked(address indexed student, uint256 amount, uint256 fee);
    event EtherReceived(address indexed sender, uint256 amount);

    constructor(address _openCertsStore, address _alumniStore, address _tokenContract) public {
        owner = msg.sender;
        openCertsStore = OpenCertsStore(_openCertsStore);
        alumniStore = AlumniStore(_alumniStore);
        tokenContract = TokenContract(_tokenContract);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    function checkScholarship(bytes32 _hash) public view returns (address) {
        require(openCertsStore.isIssued(_hash), "Scholarship not issued");
        return alumniStore.getAlumniAddress(_hash);
    }

    function unlockFunds(bytes32 _hash) public returns (bool) {
        if (!openCertsStore.isIssued(_hash)) {
            return false;
        }

        address student = alumniStore.getAlumniAddress(_hash);
        uint256 balance = tokenContract.balanceOf(address(this));
        uint256 fee = balance.mul(bitDegreeFeePercent).div(100);
        uint256 amountToSend = balance.sub(fee);

        require(tokenContract.transfer(student, amountToSend), "Transfer to student failed");
        require(tokenContract.transfer(owner, fee), "Transfer of fee failed");

        emit FundsUnlocked(student, amountToSend, fee);
        return true;
    }

    function withdrawAllTokens() public onlyOwner {
        uint256 balance = tokenContract.balanceOf(address(this));
        require(tokenContract.transfer(owner, balance), "Transfer failed");
    }

    function destroyContract() public onlyOwner {
        selfdestruct(payable(owner));
    }
}