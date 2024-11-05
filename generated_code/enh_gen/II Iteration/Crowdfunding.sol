pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Crowdfunding {
    using SafeMath for uint256;

    address public owner;
    uint256 public campaignCounter;
    Campaign[] public campaigns;
    bool private reentrantFlag;

    event CampaignStatusChanged(uint256 campaignId, CampaignStatus status);
    event ContributionMade(uint256 campaignId, address contributor, uint256 amount);
    event RefundIssued(uint256 campaignId, address contributor, uint256 amount);

    modifier noReentrancy() {
        require(!reentrantFlag, "Reentrant call detected!");
        reentrantFlag = true;
        _;
        reentrantFlag = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
        campaignCounter = 0;
        reentrantFlag = false;
    }

    struct Campaign {
        string title;
        string description;
        uint256 goal;
        uint256 deadline;
        uint256 totalContributions;
        address creator;
        CampaignStatus status;
    }

    enum CampaignStatus { ACTIVE, DELETED, SUCCESSFUL, UNSUCCEEDED }

function createCampaign(string memory _title, string memory _description, uint256 _goal, uint256 _deadline) public noReentrancy {
    require(_goal > 0, "Goal must be greater than 0");
    require(_deadline > getCurrentTime(), "Deadline must be in the future");

    campaignCounter = campaignCounter + 1;

    Campaign storage newCampaign = campaigns.push();
    newCampaign.title = _title;
    newCampaign.description = _description;
    newCampaign.goal = _goal;
    newCampaign.deadline = _deadline;
    newCampaign.totalContributions = 0;
    newCampaign.creator = msg.sender;
    newCampaign.status = CampaignStatus.ACTIVE;

    emit CampaignStatusChanged(campaignCounter, CampaignStatus.ACTIVE);
}


function contribute(uint256 campaignId) external payable noReentrancy {
    // Check if the campaign exists
    require(campaignId < campaigns.length, "Invalid campaign ID");

    // Get the campaign
    Campaign storage campaign = campaigns[campaignId];

    // Ensure the campaign status is ACTIVE
    CampaignStatus status = campaign.status;
    require(status == CampaignStatus.ACTIVE, "Campaign is not active");

    // Ensure the contribution amount is greater than zero
    require(msg.value > 0, "Contribution amount must be greater than zero");

    // Update the campaign's total contributions
    uint256 totalContributions = campaign.totalContributions;
    campaign.totalContributions = totalContributions + msg.value;

    // Emit the ContributionMade event
    emit ContributionMade(campaignId, msg.sender, msg.value);
}


function deleteCampaign(uint256 campaignId) public noReentrancy {
    // Check if the campaign exists
    require(campaignId < campaigns.length, "Invalid campaign ID");

    // Get the campaign
    Campaign storage campaign = campaigns[campaignId];

    // Ensure the caller is the creator of the campaign
    require(msg.sender == campaign.creator, "Caller is not the creator of the campaign");

    // Ensure the campaign is not already deleted or in a final state
    require(campaign.status != CampaignStatus.DELETED && campaign.status != CampaignStatus.SUCCESSFUL && campaign.status != CampaignStatus.UNSUCCEEDED, "Campaign is in a final state");

    // Change the status of the campaign to DELETED
    campaign.status = CampaignStatus.DELETED;

    // Emit the CampaignStatusChanged event
    emit CampaignStatusChanged(campaignId, CampaignStatus.DELETED);
}


function getCampaign(uint256 campaignId) public view returns (Campaign memory) {
    uint256 campaignsLength = campaigns.length;
    require(campaignId < campaignsLength, "Invalid campaign ID");

    Campaign storage campaign = campaigns[campaignId];
    return campaign;
}


function getAllCampaigns() public view returns (Campaign[] memory) {
    return campaigns;
}


function getTotalContributions(uint256 campaignId) public view returns (uint256) {
    uint256 campaignsLength = campaigns.length;
    if (campaignId >= campaignsLength) {
        revert("Invalid campaign ID");
    }

    Campaign storage campaign = campaigns[campaignId];
    uint256 totalContributions = campaign.totalContributions;
    return totalContributions;
}


function getCurrentTime() public view returns (uint256) {
    return block.timestamp;
}


function getLatestCampaigns() public view returns (Campaign[] memory) {
    uint256 totalCampaigns = campaigns.length;
    uint256 numCampaignsToReturn = totalCampaigns < 4 ? totalCampaigns : 4;

    Campaign[] memory latestCampaigns = new Campaign[](numCampaignsToReturn);

    for (uint256 i = 0; i < numCampaignsToReturn; i = i + 1) {
        uint256 index = totalCampaigns - 1 - i;
        Campaign storage campaign = campaigns[index];

        latestCampaigns[i] = campaign;
    }

    return latestCampaigns;
}


}