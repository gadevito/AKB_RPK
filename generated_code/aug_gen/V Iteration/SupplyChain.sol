// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SupplyChain {
    using SafeMath for uint256;

    struct Step {
        address creator;
        string item;
        uint256[] previousSteps;
    }

    mapping(uint256 => Step) public steps;
    mapping(string => uint256) public lastStep;
    mapping(string => bool) private itemExists;
    uint256 public totalSteps;

    event StepCreated(uint256 stepId, address creator, string item, uint256[] previousSteps);

    function createStep(string memory _item, uint256[] memory _previousSteps) public returns (uint256) {
        require(!itemExists[_item], "Item already has a supply chain");

        uint256 stepId = totalSteps.add(1);
        Step memory newStep = Step({
            creator: msg.sender,
            item: _item,
            previousSteps: _previousSteps
        });

        steps[stepId] = newStep;
        lastStep[_item] = stepId;
        itemExists[_item] = true;
        totalSteps = stepId;

        emit StepCreated(stepId, msg.sender, _item, _previousSteps);

        return stepId;
    }

    function isLastStep(uint256 _stepId) public view returns (bool) {
        Step memory step = steps[_stepId];
        return lastStep[step.item] == _stepId;
    }

    function getPreviousSteps(uint256 _stepId) public view returns (uint256[] memory) {
        return steps[_stepId].previousSteps;
    }
}