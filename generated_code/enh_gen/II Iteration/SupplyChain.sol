pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SupplyChain {
    using SafeMath for uint256;

    uint256 public stepCount;
    mapping(uint256 => Step) public steps;
    mapping(string => uint256) public lastStep;
    mapping(uint256 => bool) public stepExists;

    event StepCreated(uint256 indexed stepId, address indexed creator, string item, uint256[] previousSteps);

    modifier stepDoesNotExist(uint256 stepId) {
        require(!stepExists[stepId], "Step already exists");
        _;
    }

    struct Step {
        address creator;
        string item;
        uint256[] previousSteps;
    }

    constructor() public {
        stepCount = 0;
    }

function createStep(string memory item, uint256[] memory previousSteps) public returns (uint256) {
    require(!stepExists[stepCount], "Step already exists");

    uint256 currentLastStep = lastStep[item];
    require(currentLastStep == 0, "Item already has a supply chain");

    uint256 newStepId = stepCount;

    Step storage newStep = steps[newStepId];
    newStep.creator = msg.sender;
    newStep.item = item;
    newStep.previousSteps = previousSteps;

    lastStep[item] = newStepId;
    stepCount = stepCount + 1;
    stepExists[newStepId] = true;

    emit StepCreated(newStepId, msg.sender, item, previousSteps);

    return newStepId;
}


function isLastStep(uint256 stepId) public view returns (bool) {
    // Ensure the stepId exists
    bool exists = stepExists[stepId];
    require(exists, "Step does not exist");

    // Retrieve the item associated with the given stepId
    Step storage step = steps[stepId];
    string memory item = step.item;

    // Check if the stepId matches the lastStep for the retrieved item
    uint256 lastStepId = lastStep[item];
    bool isLast = (stepId == lastStepId);

    return isLast;
}


function getPreviousSteps(uint256 stepId) public view returns (uint256[] memory) {
    require(stepExists[stepId], "Step does not exist");

    Step storage step = steps[stepId];
    uint256[] memory previousSteps = step.previousSteps;

    return previousSteps;
}


}