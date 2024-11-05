// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";

contract DigitalAllowance is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    IERC20 public usdcToken;
    address public child;
    uint256 public allowancePerTask;

    struct Task {
        string description;
        bool completed;
        bool approved;
    }

    Counters.Counter private taskIdCounter;
    mapping(uint256 => Task) public tasks;

    event TaskAdded(uint256 taskId, string description);
    event TaskCompleted(uint256 taskId, address by);
    event TaskApproved(uint256 taskId);
    event AllowancePaid(address to, uint256 amount);

    constructor(address _child, address _usdcToken, uint256 _allowancePerTask) {
        require(_child != address(0), "Invalid child address.");
        require(_usdcToken != address(0), "Invalid token address.");
        child = _child;
        usdcToken = IERC20(_usdcToken);
        allowancePerTask = _allowancePerTask;
    }

    function addTask(string memory _description) public onlyOwner {
        taskIdCounter.increment();
        uint256 taskId = taskIdCounter.current();
        tasks[taskId] = Task(_description, false, false);
        emit TaskAdded(taskId, _description);
    }

    function completeTask(uint256 _taskId) public {
        require(_taskId <= taskIdCounter.current(), "Invalid task ID.");
        Task storage task = tasks[_taskId];
        require(!task.completed, "Task already completed.");
        task.completed = true;
        emit TaskCompleted(_taskId, msg.sender);
    }

    function approveTask(uint256 _taskId) public onlyOwner {
        require(_taskId <= taskIdCounter.current(), "Invalid task ID.");
        Task storage task = tasks[_taskId];
        require(task.completed, "Task not completed yet.");
        require(!task.approved, "Task already approved.");
        task.approved = true;
        emit TaskApproved(_taskId);
    }

    function payAllowance() public onlyOwner nonReentrant {
        uint256 totalPayment = 0;
        for (uint256 i = 1; i <= taskIdCounter.current(); i++) {
            if (tasks[i].approved) {
                totalPayment += allowancePerTask;
                tasks[i].approved = false;
            }
        }
        require(totalPayment > 0, "No approved tasks to pay for.");
        require(usdcToken.balanceOf(address(this)) >= totalPayment, "Insufficient balance in contract.");
        usdcToken.transfer(child, totalPayment);
        emit AllowancePaid(child, totalPayment);
    }

    function depositAllowanceTokens(uint256 _amount) public onlyOwner {
        usdcToken.transferFrom(msg.sender, address(this), _amount);
    }

    function setAllowancePerTask(uint256 _newAllowancePerTask) public onlyOwner {
        allowancePerTask = _newAllowancePerTask;
    }
}
