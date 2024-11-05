pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MedicalInsurance {
    uint256 public policyCounter;
    address public owner;
    IERC20 public erc20Token;

    struct Policy {
        uint256 id;
        address policyholder;
        uint256 premium;
        uint256 coverageAmount;
        bool active;
    }

    mapping(uint256 => Policy) public policies;
    mapping(address => uint256[]) public policyIdsByHolder;

    event PolicyCreated(uint256 indexed policyId, address indexed policyholder, uint256 premium, uint256 coverageAmount);
    event PolicyActivated(uint256 indexed policyId);
    event PolicyDeactivated(uint256 indexed policyId);
    event ClaimPaid(uint256 indexed policyId, uint256 claimAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier onlyPolicyholder(uint256 policyId) {
        require(msg.sender == policies[policyId].policyholder, "Only the policyholder can call this function");
        _;
    }

    constructor(address _erc20Token) {
        owner = msg.sender;
        erc20Token = IERC20(_erc20Token);
    }

function createPolicy(address _policyholder, uint256 _premium, uint256 _coverageAmount) external {
    require(_policyholder != address(0), "Invalid policyholder address");
    require(_premium > 0, "Premium must be greater than zero");
    require(_coverageAmount > 0, "Coverage amount must be greater than zero");

    policyCounter = policyCounter + 1;
    uint256 newPolicyId = policyCounter;

    Policy storage newPolicy = policies[newPolicyId];
    newPolicy.id = newPolicyId;
    newPolicy.policyholder = _policyholder;
    newPolicy.premium = _premium;
    newPolicy.coverageAmount = _coverageAmount;
    newPolicy.active = false;

    policyIdsByHolder[_policyholder].push(newPolicyId);

    emit PolicyCreated(newPolicyId, _policyholder, _premium, _coverageAmount);
}


function getPoliciesByHolder(address _policyholder) public view returns (uint256[] memory) {
    return policyIdsByHolder[_policyholder];
}


function activatePolicy(uint256 policyId) external onlyPolicyholder(policyId) {
    // Check if the policy exists
    Policy storage policy = policies[policyId];
    require(policy.policyholder != address(0), "Policy does not exist");

    // Verify that the caller is the policyholder
    require(msg.sender == policy.policyholder, "Caller is not the policyholder");

    // Ensure the policy is currently inactive
    require(!policy.active, "Policy is already active");

    // Transfer the premium amount from the policyholder to the contract
    bool success = erc20Token.transferFrom(policy.policyholder, address(this), policy.premium);
    require(success, "ERC20 token transfer failed");

    // Update the policy's status to active
    policy.active = true;

    // Emit the PolicyActivated event
    emit PolicyActivated(policyId);
}


function deactivatePolicy(uint256 policyId) external onlyOwner {
    Policy storage policy = policies[policyId];

    require(policy.policyholder != address(0), "Policy does not exist");
    require(policy.active, "Policy is already inactive");

    policy.active = false;

    emit PolicyDeactivated(policyId);
}


function payOutClaim(uint256 policyId, uint256 claimAmount) external onlyOwner {
    // Check if the policy exists
    Policy storage policy = policies[policyId];
    require(policy.policyholder != address(0), "Policy does not exist");

    // Ensure the policy is active
    require(policy.active, "Policy is not active");

    // Verify that the claimAmount does not exceed the policy's coverage amount
    require(claimAmount <= policy.coverageAmount, "Claim amount exceeds coverage");

    // Transfer the claimAmount to the policyholder's address using the ERC20 token
    address policyholder = policy.policyholder;
    bool success = erc20Token.transfer(policyholder, claimAmount);
    require(success, "ERC20 token transfer failed");

    // Emit the ClaimPaid event with the policyId and claimAmount
    emit ClaimPaid(policyId, claimAmount);
}


}