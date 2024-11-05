pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MedicalInsurance {
    address public owner;
    uint256 public policyCounter;
    IERC20 public erc20Token;

    struct Policy {
        address policyholder;
        uint256 premium;
        uint256 coverageAmount;
        bool active;
    }

    mapping(uint256 => Policy) public policies;
    mapping(address => uint256[]) public policyIdsByHolder;

    event PolicyCreated(uint256 policyId, address policyholder, uint256 premium, uint256 coverageAmount);
    event PolicyActivated(uint256 policyId);
    event PolicyDeactivated(uint256 policyId);
    event ClaimPaid(uint256 policyId, uint256 claimAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier onlyPolicyholder(uint256 policyId) {
        require(policies[policyId].policyholder == msg.sender, "Only the policyholder can call this function");
        _;
    }

    constructor(address _erc20Token) {
        owner = msg.sender;
        erc20Token = IERC20(_erc20Token);
    }

function createPolicy(address policyholder, uint256 premium, uint256 coverageAmount) public {
    require(policyholder != address(0), "Invalid policyholder address");
    require(premium > 0, "Premium must be greater than zero");
    require(coverageAmount > 0, "Coverage amount must be greater than zero");

    policyCounter = policyCounter + 1;
    uint256 newPolicyId = policyCounter;

    Policy storage newPolicy = policies[newPolicyId];
    newPolicy.policyholder = policyholder;
    newPolicy.premium = premium;
    newPolicy.coverageAmount = coverageAmount;
    newPolicy.active = false;

    policyIdsByHolder[policyholder].push(newPolicyId);

    emit PolicyCreated(newPolicyId, policyholder, premium, coverageAmount);
}


function getPoliciesByHolder(address _policyholder) public view returns (uint256[] memory) {
    return policyIdsByHolder[_policyholder];
}


function activatePolicy(uint256 policyId) public onlyPolicyholder(policyId) {
    // Check if the policy exists
    Policy storage policy = policies[policyId];
    require(policy.policyholder != address(0), "Policy does not exist");

    // Ensure the policy is currently inactive
    require(!policy.active, "Policy is already active");

    // Verify that the caller is the policyholder of the policy
    require(policy.policyholder == msg.sender, "Caller is not the policyholder");

    // Transfer the premium amount from the policyholder to the contract
    bool success = erc20Token.transferFrom(msg.sender, address(this), policy.premium);
    require(success, "ERC20 token transfer failed");

    // Update the policy's status to active
    policy.active = true;

    // Emit the PolicyActivated event
    emit PolicyActivated(policyId);
}


function deactivatePolicy(uint256 policyId) public onlyOwner {
    // Check if the policy with the given policyId exists
    Policy storage policy = policies[policyId];
    require(policy.policyholder != address(0), "Policy does not exist");

    // Check if the policy is already inactive
    require(policy.active, "Policy is already inactive");

    // Update the policy's status to inactive
    policy.active = false;

    // Emit the PolicyDeactivated event with the policyId
    emit PolicyDeactivated(policyId);
}


function payClaim(uint256 policyId, uint256 claimAmount) external onlyOwner {
    // Check if the policy exists
    Policy storage policy = policies[policyId];
    require(policy.policyholder != address(0), "Policy does not exist");

    // Ensure the policy is active
    require(policy.active, "Policy is not active");

    // Ensure the claimAmount does not exceed the policy's coverage amount
    require(claimAmount <= policy.coverageAmount, "Claim amount exceeds coverage amount");

    // Transfer the claimAmount to the policyholder's address using the ERC20 token
    bool success = erc20Token.transfer(policy.policyholder, claimAmount);
    require(success, "ERC20 token transfer failed");

    // Emit the ClaimPaid event with the policyId and claimAmount
    emit ClaimPaid(policyId, claimAmount);
}


}