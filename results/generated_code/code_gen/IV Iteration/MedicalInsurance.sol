pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MedicalInsurance {
    uint256 public policyCounter;
    address public owner;
    IERC20 public erc20Token;

    struct Policy {
        address policyholder;
        uint256 premium;
        uint256 coverageAmount;
        bool active;
    }

    mapping(uint256 => Policy) public policies;
    mapping(address => uint256[]) public policyIdsByHolder;

    event PolicyCreated(uint256 policyId, address policyholder, uint256 premium, uint256 coverageAmount, bool active);
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

function createPolicy(address policyholder, uint256 premium, uint256 coverageAmount) external {
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

    emit PolicyCreated(newPolicyId, policyholder, premium, coverageAmount, false);
}


function getPoliciesByHolder(address _policyholder) public view returns (uint256[] memory) {
    uint256[] memory policyIds = policyIdsByHolder[_policyholder];
    return policyIds;
}


function activatePolicy(uint256 policyId) external onlyPolicyholder(policyId) {
    // Retrieve the policy from the mapping
    Policy storage policy = policies[policyId];

    // Check if the policy is inactive
    require(!policy.active, "Policy is already active");

    // Transfer the premium amount from the policyholder to the contract
    bool success = erc20Token.transferFrom(msg.sender, address(this), policy.premium);
    require(success, "ERC20 token transfer failed");

    // Update the policy status to active
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


function payClaim(uint256 policyId, uint256 claimAmount) external onlyOwner {
    // Retrieve the policy from the policies mapping
    Policy storage policy = policies[policyId];

    // Check if the policy is active
    bool isActive = policy.active;
    require(isActive, "Policy is not active");

    // Ensure the claimAmount does not exceed the policy's coverage amount
    uint256 coverageAmount = policy.coverageAmount;
    require(claimAmount <= coverageAmount, "Claim amount exceeds coverage amount");

    // Transfer the claimAmount to the policyholder's address using the erc20Token contract
    address policyholder = policy.policyholder;
    (bool success,) = address(erc20Token).call(abi.encodeWithSignature("transfer(address,uint256)", policyholder, claimAmount));
    require(success, "ERC20 token transfer failed");

    // Emit the ClaimPaid event with the policyId and claimAmount
    emit ClaimPaid(policyId, claimAmount);
}


}