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
    // Ensure that the stepId exists in the steps mapping
    require(stepExists[stepId], "Step does not exist");

    // Retrieve the step from the steps mapping using stepId
    Step storage step = steps[stepId];

    // Extract the item associated with the step
    string memory item = step.item;

    // Compare stepId with the value in the lastStep mapping for the item
    uint256 lastStepId = lastStep[item];

    // Return true if stepId matches the last step ID for the item, otherwise return false
    return stepId == lastStepId;
}


function getPreviousSteps(uint256 stepId) public view returns (uint256[] memory) {
    // Check if the step with the given stepId exists
    bool exists = stepExists[stepId];
    require(exists, "Step does not exist");

    // Retrieve the previousSteps array from the steps mapping using the stepId
    Step storage step = steps[stepId];
    uint256[] memory previousSteps = step.previousSteps;

    // Return the previousSteps array
    return previousSteps;
}


}