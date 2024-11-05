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

    uint256 stepId = stepCount;
    stepCount = stepCount + 1;

    require(!stepExists[stepId], "Step already exists");

    Step storage newStep = steps[stepId];
    newStep.creator = msg.sender;
    newStep.item = item;
    newStep.previousSteps = previousSteps;

    lastStep[item] = stepId;
    stepExists[stepId] = true;

    emit StepCreated(stepId, msg.sender, item, previousSteps);

    return stepId;
}


function isLastStep(uint256 stepId) public view returns (bool) {
    require(stepExists[stepId], "Step does not exist");

    Step storage step = steps[stepId];
    string memory item = step.item;

    uint256 lastStepId = lastStep[item];
    return stepId == lastStepId;
}


function getPreviousSteps(uint256 stepId) public view returns (uint256[] memory) {
    require(stepExists[stepId], "Step does not exist");

    Step storage step = steps[stepId];
    uint256[] memory previousSteps = step.previousSteps;

    return previousSteps;
}


}