// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./IERC20.sol";

contract MedicalInsurance is Ownable, AccessControl {
    IERC20 public token;
    bytes32 public constant POLICY_HOLDER = keccak256("POLICY_HOLDER");

    struct Policy {
        uint256 id;
        address policyHolder;
        uint256 premium;
        uint256 coverageAmount;
        bool isActive;
    }

    mapping(uint256 => Policy) public policies;
    mapping(address => uint256[]) public policyIds;
    uint256 public nextPolicyId;

    event PolicyCreated(uint256 id, address policyHolder, uint256 premium, uint256 coverageAmount);
    event PolicyActivated(uint256 id);
    event PolicyDeactivated(uint256 id);
    event ClaimPaid(uint256 id, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
        nextPolicyId = 1;
    }

    function createPolicy(uint256 premium, uint256 coverageAmount, address policyHolder) external {
        require(premium > 0, "Premium must be greater than zero");
        require(coverageAmount > 0, "Coverage amount must be greater than zero");

        policies[nextPolicyId] = Policy({
            id: nextPolicyId,
            policyHolder: policyHolder,
            premium: premium,
            coverageAmount: coverageAmount,
            isActive: false
        });

        policyIds[policyHolder].push(nextPolicyId);
        _setupRole(POLICY_HOLDER, policyHolder);

        emit PolicyCreated(nextPolicyId, policyHolder, premium, coverageAmount);
        nextPolicyId++;
    }

    function activatePolicy(uint256 id, address policyHolder) external onlyRole(POLICY_HOLDER) {
        Policy storage policy = policies[id];
        require(policy.policyHolder == policyHolder, "Not the policy holder");
        require(!policy.isActive, "Policy is already active");

        token.transferFrom(policyHolder, address(this), policy.premium);
        policy.isActive = true;

        emit PolicyActivated(id);
    }

    function deactivatePolicy(uint256 id) external onlyOwner {
        Policy storage policy = policies[id];
        require(policy.isActive, "Policy is already inactive");

        policy.isActive = false;

        emit PolicyDeactivated(id);
    }

    function payClaim(uint256 id, uint256 amount) external onlyOwner {
        Policy storage policy = policies[id];
        require(policy.isActive, "Policy is not active");
        require(amount <= policy.coverageAmount, "Amount exceeds coverage");

        token.transfer(policy.policyHolder, amount);
        emit ClaimPaid(id, amount);
    }

    function getPoliciesByHolder(address holder) external view returns (uint256[] memory) {
        return policyIds[holder];
    }
}