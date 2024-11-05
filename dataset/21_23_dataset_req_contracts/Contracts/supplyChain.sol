pragma solidity ^0.5.0;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title Supply Chain
 * @author Alberto Cuesta Canada
 * @notice Implements a basic compositional supply chain contract.
 */
contract SupplyChain {
    using SafeMath for uint256;
    event StepCreated(uint256 step);

    struct Step {
        address creator;
        uint256 item;
        uint256[] precedents;
    }

    mapping(uint256 => Step) public steps;

    uint256 public totalSteps;

    mapping(uint256 => uint256) public lastSteps;

    function newStep(
        uint256 _item,
        uint256[] memory _precedents
    ) public returns (uint256) {
        for (uint i = 0; i < _precedents.length; i++) {
            require(isLastStep(_precedents[i]), "Append only on last steps.");
        }
        bool repeatInstance = false;
        for (uint i = 0; i < _precedents.length; i++) {
            if (steps[_precedents[i]].item == _item) {
                repeatInstance = true;
                break;
            }
        }
        if (!repeatInstance) {
            require(lastSteps[_item] == 0, "Instance not valid.");
        }

        steps[totalSteps] = Step(msg.sender, _item, _precedents);
        uint256 step = totalSteps;
        totalSteps += 1;
        lastSteps[_item] = step;
        emit StepCreated(step);
        return step;
    }

    function isLastStep(uint256 _step) public view returns (bool) {
        return lastSteps[steps[_step].item] == _step;
    }

    function getprecedents(
        uint256 _step
    ) public view returns (uint256[] memory) {
        return steps[_step].precedents;
    }
}
