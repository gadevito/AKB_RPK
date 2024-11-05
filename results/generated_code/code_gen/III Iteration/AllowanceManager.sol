pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AllowanceManager is ReentrancyGuard {
    IERC20 public usdcToken;
    address public childAddress;
    uint256 public allowancePerTask;
    uint256 public taskCounter;
    address public owner;

    struct Task {
        string description;
        bool completed;
        bool approved;
    }

    mapping(uint256 => Task) public tasks;

    event TaskAdded(uint256 taskId, string description);
    event TaskCompleted(uint256 taskId);
    event TaskApproved(uint256 taskId);
    event AllowancePaid(uint256 totalAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor(address _usdcToken, address _childAddress, uint256 _allowancePerTask) {
        require(_childAddress != address(0), "Child address cannot be zero");
        usdcToken = IERC20(_usdcToken);
        childAddress = _childAddress;
        allowancePerTask = _allowancePerTask;
        owner = msg.sender;
        taskCounter = 0;
    }

function addTask(string memory _description) public onlyOwner {
    taskCounter = taskCounter + 1;

    Task storage newTask = tasks[taskCounter];
    newTask.description = _description;
    newTask.completed = false;
    newTask.approved = false;

    emit TaskAdded(taskCounter, _description);
}


function completeTask(uint256 taskId) public {
    // Ensure the task with the given taskId exists
    require(taskId <= taskCounter, "Task does not exist");

    // Access the task from the mapping
    Task storage task = tasks[taskId];

    // Check that the task is not already completed
    require(!task.completed, "Task is already completed");

    // Update the task's state to completed
    task.completed = true;

    // Emit the TaskCompleted event with the taskId
    emit TaskCompleted(taskId);
}


function approveTask(uint256 taskId) external onlyOwner {
    // Ensure the task with the given taskId exists
    require(taskId <= taskCounter, "Task does not exist");

    // Access the task from the mapping
    Task storage task = tasks[taskId];

    // Check that the task is marked as completed
    require(task.completed, "Task is not completed");

    // Ensure the task is not already approved
    require(!task.approved, "Task is already approved");

    // Update the task's state to approved
    task.approved = true;

    // Emit the TaskApproved event with the taskId
    emit TaskApproved(taskId);
}


function payAllowance() external onlyOwner nonReentrant {
    uint256 totalApprovedTasks = 0;
    uint256 totalTasks = taskCounter;

    for (uint256 i = 1; i <= totalTasks; i = i + 1) {
        Task storage task = tasks[i];
        if (task.approved) {
            totalApprovedTasks = totalApprovedTasks + 1;
        }
    }

    require(totalApprovedTasks > 0, "No approved tasks to pay allowance for");

    uint256 totalAllowance = totalApprovedTasks * allowancePerTask;
    uint256 contractBalance = usdcToken.balanceOf(address(this));

    require(contractBalance >= totalAllowance, "Insufficient contract balance to pay allowance");

    bool success = usdcToken.transfer(childAddress, totalAllowance);
    require(success, "Transfer failed");

    emit AllowancePaid(totalAllowance);
}


function depositTokens(uint256 amount) external onlyOwner {
    require(amount > 0, "Amount must be greater than zero");

    bool success = usdcToken.transferFrom(msg.sender, address(this), amount);
    require(success, "Token transfer failed");

    // Emit an event if needed
    // emit TokensDeposited(amount);
}


function updateAllowancePerTask(uint256 _newAllowancePerTask) external onlyOwner {
    allowancePerTask = _newAllowancePerTask;
}


}