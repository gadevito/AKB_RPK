pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MedicalInsurance {
    address public owner;
    IERC20 public token;

    struct Policy {
        uint256 id;
        address policyholder;
        uint256 premium;
        uint256 coverageAmount;
        bool active;
    }

    uint256 public nextPolicyId;
    mapping(uint256 => Policy) public policies;
    mapping(address => uint256[]) public policyIdsByHolder;

    event PolicyCreated(uint256 id, address policyholder, uint256 premium, uint256 coverageAmount);
    event PolicyActivated(uint256 id);
    event PolicyDeactivated(uint256 id);
    event ClaimPaid(uint256 id, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyPolicyholder(uint256 policyId) {
        require(policies[policyId].policyholder == msg.sender, "Only policyholder can perform this action");
        _;
    }

    constructor(IERC20 _token) {
        owner = msg.sender;
        token = _token;
    }

    function createPolicy(address policyholder, uint256 premium, uint256 coverageAmount) public onlyOwner {
        policies[nextPolicyId] = Policy(nextPolicyId, policyholder, premium, coverageAmount, false);
        policyIdsByHolder[policyholder].push(nextPolicyId);
        emit PolicyCreated(nextPolicyId, policyholder, premium, coverageAmount);
        nextPolicyId++;
    }

    function getPoliciesByHolder(address policyholder) public view returns (uint256[] memory) {
        return policyIdsByHolder[policyholder];
    }

    function activatePolicy(uint256 policyId) public onlyPolicyholder(policyId) {
        Policy storage policy = policies[policyId];
        require(!policy.active, "Policy is already active");
        require(token.transferFrom(msg.sender, address(this), policy.premium), "Premium payment failed");

        policy.active = true;
        emit PolicyActivated(policyId);
    }

    function deactivatePolicy(uint256 policyId) public onlyOwner {
        Policy storage policy = policies[policyId];
        policy.active = false;
        emit PolicyDeactivated(policyId);
    }

    function payClaim(uint256 policyId, uint256 amount) public onlyOwner {
        Policy storage policy = policies[policyId];
        require(policy.active, "Policy is not active");
        require(amount <= policy.coverageAmount, "Claim amount exceeds coverage");

        require(token.transfer(policy.policyholder, amount), "Claim payment failed");
        emit ClaimPaid(policyId, amount);
    }
}