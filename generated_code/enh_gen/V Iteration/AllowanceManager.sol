pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AllowanceManager is ReentrancyGuard {
    IERC20 public usdcToken;
    address public childAddress;
    uint256 public allowancePerTask;
    uint256 public taskCounter;
    mapping(uint256 => Task) public tasks;
    address public owner;

    event TaskAdded(uint256 taskId, string description);
    event TaskCompleted(uint256 taskId);
    event TaskApproved(uint256 taskId);
    event AllowancePaid(uint256 totalAmount);
    event TokensDeposited(uint256 amount); // Declare the missing event

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier taskExists(uint256 taskId) {
        require(bytes(tasks[taskId].description).length > 0, "Task does not exist");
        _;
    }

    modifier nonZeroAddress(address _address) {
        require(_address != address(0), "Address cannot be zero");
        _;
    }

    struct Task {
        string description;
        bool completed;
        bool approved;
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
        uint256 newTaskId = taskCounter;

        Task storage newTask = tasks[newTaskId];
        newTask.description = _description;
        newTask.completed = false;
        newTask.approved = false;

        emit TaskAdded(newTaskId, _description);
    }

    function completeTask(uint256 taskId) public {
        // Ensure the task with the given taskId exists
        require(bytes(tasks[taskId].description).length > 0, "Task does not exist");

        // Check that the task is not already completed
        bool isCompleted = tasks[taskId].completed;
        require(!isCompleted, "Task is already completed");

        // Update the task's state to completed
        tasks[taskId].completed = true;

        // Emit the TaskCompleted event with the taskId
        emit TaskCompleted(taskId);
    }

    function approveTask(uint256 taskId) external onlyOwner taskExists(taskId) {
        Task storage task = tasks[taskId];

        require(task.completed, "Task is not completed");
        require(!task.approved, "Task is already approved");

        task.approved = true;

        emit TaskApproved(taskId);
    }

    function payAllowance() external onlyOwner nonReentrant {
        uint256 totalAllowance = 0;
        uint256 taskCount = taskCounter;
        uint256 allowance = allowancePerTask;
        address child = childAddress;

        for (uint256 i = 1; i <= taskCount; i = i + 1) {
            Task storage task = tasks[i];
            bool isApproved = task.approved;
            if (isApproved) {
                totalAllowance = totalAllowance + allowance;
            }
        }

        require(totalAllowance > 0, "No approved tasks available");
        uint256 contractBalance = usdcToken.balanceOf(address(this));
        require(contractBalance >= totalAllowance, "Insufficient contract balance");

        bool success = usdcToken.transfer(child, totalAllowance);
        require(success, "Transfer failed");

        emit AllowancePaid(totalAllowance);
    }

    function depositTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");

        bool success = usdcToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        // Emit an event to log the deposit
        emit TokensDeposited(amount);
    }

    function updateAllowancePerTask(uint256 _newAllowancePerTask) external onlyOwner {
        allowancePerTask = _newAllowancePerTask;
        // Optionally emit an event to log the update
        // emit AllowancePerTaskUpdated(_newAllowancePerTask);
    }
}