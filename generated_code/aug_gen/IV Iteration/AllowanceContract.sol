pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract AllowanceContract is ReentrancyGuard {
    IERC20 public usdcToken;
    address public owner;
    address public child;
    uint256 public allowancePerTask;

    struct Task {
        string description;
        bool completed;
        bool approved;
    }

    mapping(uint256 => Task) public tasks;
    uint256 public taskCount;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Invalid address");
        _;
    }

    event TaskAdded(uint256 taskId, string description);
    event TaskCompleted(uint256 taskId);
    event TaskApproved(uint256 taskId);
    event AllowancePaid(uint256 totalAmount);
    event TokensDeposited(uint256 amount);
    event AllowanceUpdated(uint256 newAllowance);

    constructor(address _usdcToken, address _child, uint256 _allowancePerTask) validAddress(_child) {
        usdcToken = IERC20(_usdcToken);
        owner = msg.sender;
        child = _child;
        allowancePerTask = _allowancePerTask;
    }

    function addTask(string memory _description) public onlyOwner {
        taskCount++;
        tasks[taskCount] = Task(_description, false, false);
        emit TaskAdded(taskCount, _description);
    }

    function completeTask(uint256 _taskId) public {
        require(_taskId > 0 && _taskId <= taskCount, "Task does not exist");
        Task storage task = tasks[_taskId];
        require(!task.completed, "Task already completed");
        task.completed = true;
        emit TaskCompleted(_taskId);
    }

    function approveTask(uint256 _taskId) public onlyOwner {
        require(_taskId > 0 && _taskId <= taskCount, "Task does not exist");
        Task storage task = tasks[_taskId];
        require(task.completed, "Task not completed");
        require(!task.approved, "Task already approved");
        task.approved = true;
        emit TaskApproved(_taskId);
    }

    function payAllowance() public onlyOwner nonReentrant {
        uint256 totalApprovedTasks = 0;
        for (uint256 i = 1; i <= taskCount; i++) {
            if (tasks[i].approved) {
                totalApprovedTasks++;
                tasks[i].approved = false; // Reset the approval status after payment
            }
        }
        require(totalApprovedTasks > 0, "No approved tasks");
        uint256 totalAmount = totalApprovedTasks * allowancePerTask;
        require(usdcToken.balanceOf(address(this)) >= totalAmount, "Insufficient token balance");
        usdcToken.transfer(child, totalAmount);
        emit AllowancePaid(totalAmount);
    }

    function depositTokens(uint256 _amount) public onlyOwner {
        require(usdcToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
        emit TokensDeposited(_amount);
    }

    function updateAllowance(uint256 _newAllowance) public onlyOwner {
        allowancePerTask = _newAllowance;
        emit AllowanceUpdated(_newAllowance);
    }
}