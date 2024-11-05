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
    require(lastStep[item] == 0, "Item already has a supply chain");

    for (uint256 i = 0; i < previousSteps.length; i = i + 1) {
        require(stepExists[previousSteps[i]], "One of the previous steps does not exist");
    }

    stepCount = stepCount + 1;

    Step storage newStep = steps[stepCount];
    newStep.creator = msg.sender;
    newStep.item = item;
    newStep.previousSteps = previousSteps;

    lastStep[item] = stepCount;
    stepExists[stepCount] = true;

    emit StepCreated(stepCount, msg.sender, item, previousSteps);

    return stepCount;
}


function isLastStep(uint256 stepId) public view returns (bool) {
    // Ensure the stepId exists
    bool exists = stepExists[stepId];
    require(exists, "Step does not exist");

    // Retrieve the step from the steps mapping
    Step storage step = steps[stepId];

    // Extract the item associated with the step
    string memory item = step.item;

    // Compare stepId with the value in the lastStep mapping for the item
    uint256 lastStepId = lastStep[item];
    bool isLast = (stepId == lastStepId);

    return isLast;
}


function getPreviousSteps(uint256 stepId) public view returns (uint256[] memory) {
    // Check if the step with the given stepId exists
    bool exists = stepExists[stepId];
    require(exists, "Step does not exist");

    // Retrieve the step from the steps mapping
    Step storage step = steps[stepId];

    // Return the array of previous steps associated with the given stepId
    return step.previousSteps;
}


}