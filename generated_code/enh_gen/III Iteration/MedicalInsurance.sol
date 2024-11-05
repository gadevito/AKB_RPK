pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MedicalInsurance {
    address public owner;
    uint256 public policyCounter;
    IERC20 public erc20Token;

    struct Policy {
        address policyHolder;
        uint256 premium;
        uint256 coverageAmount;
        bool active;
    }

    mapping(uint256 => Policy) public policies;
    mapping(address => uint256[]) public policyIdsByHolder;

    event PolicyCreated(uint256 policyId, address policyHolder, uint256 premium, uint256 coverageAmount, bool active);
    event PolicyActivated(uint256 policyId);
    event PolicyDeactivated(uint256 policyId);
    event ClaimPaid(uint256 policyId, uint256 claimAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier onlyPolicyHolder(uint256 policyId) {
        require(policies[policyId].policyHolder == msg.sender, "Only the policyholder can call this function");
        _;
    }

    constructor(address _erc20Token) {
        owner = msg.sender;
        erc20Token = IERC20(_erc20Token);
    }

function createPolicy(address policyHolder, uint256 premium, uint256 coverageAmount) public {
    require(policyHolder != address(0), "Invalid policy holder address");
    require(premium > 0, "Premium must be greater than zero");
    require(coverageAmount > 0, "Coverage amount must be greater than zero");

    policyCounter = policyCounter + 1;
    uint256 newPolicyId = policyCounter;

    Policy storage newPolicy = policies[newPolicyId];
    newPolicy.policyHolder = policyHolder;
    newPolicy.premium = premium;
    newPolicy.coverageAmount = coverageAmount;
    newPolicy.active = false;

    policyIdsByHolder[policyHolder].push(newPolicyId);

    emit PolicyCreated(newPolicyId, policyHolder, premium, coverageAmount, false);
}


function getPoliciesByHolder(address _policyHolder) public view returns (uint256[] memory) {
    return policyIdsByHolder[_policyHolder];
}


function activatePolicy(uint256 policyId) external onlyPolicyHolder(policyId) {
    // Check if the policy exists and is inactive
    Policy storage policy = policies[policyId];
    require(policy.policyHolder != address(0), "Policy does not exist");
    require(!policy.active, "Policy is already active");

    // Ensure the caller is the policyholder of the policy
    require(policy.policyHolder == msg.sender, "Caller is not the policyholder");

    // Transfer the premium amount from the policyholder to the contract
    bool success = erc20Token.transferFrom(msg.sender, address(this), policy.premium);
    require(success, "ERC20 token transfer failed");

    // Update the policy status to active
    policy.active = true;

    // Emit the PolicyActivated event with the policyId
    emit PolicyActivated(policyId);
}


function deactivatePolicy(uint256 policyId) public onlyOwner {
    // Check if the policy exists by verifying if the policyId is valid
    Policy storage policy = policies[policyId];
    require(policy.policyHolder != address(0), "Policy does not exist");

    // Check if the policy is already inactive
    require(policy.active, "Policy is already inactive");

    // Update the policy's active status to false
    policy.active = false;

    // Emit the PolicyDeactivated event with the policyId
    emit PolicyDeactivated(policyId);
}


function payClaim(uint256 policyId, uint256 claimAmount) external onlyOwner {
    // Check if the policy exists
    Policy storage policy = policies[policyId];
    require(policy.coverageAmount > 0, "Policy does not exist");

    // Ensure the policy is active
    require(policy.active, "Policy is not active");

    // Ensure the claim amount does not exceed the policy's coverage amount
    require(claimAmount <= policy.coverageAmount, "Claim amount exceeds coverage amount");

    // Transfer the claim amount to the policyholder's address using the erc20Token contract
    bool success = erc20Token.transfer(policy.policyHolder, claimAmount);
    require(success, "ERC20 token transfer failed");

    // Emit the ClaimPaid event with the policyId and claimAmount
    emit ClaimPaid(policyId, claimAmount);
}


}