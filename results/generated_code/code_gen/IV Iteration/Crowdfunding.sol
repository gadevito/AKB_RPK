pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Crowdfunding {
    using SafeMath for uint256;

    address public owner;
    uint256 public campaignCounter;
    mapping(uint256 => Campaign) public campaigns;
    bool private reentrantFlag;

    event CampaignStatusChanged(uint256 campaignId, CampaignStatus status);
    event ContributionMade(uint256 campaignId, address contributor, uint256 amount);
    event RefundIssued(uint256 campaignId, address contributor, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier nonReentrant() {
        require(!reentrantFlag, "Reentrant call");
        reentrantFlag = true;
        _;
        reentrantFlag = false;
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
        CampaignStatus status;
        address creator;
        mapping(address => uint256) contributions;
    }

    struct CampaignView {
        string title;
        string description;
        uint256 goal;
        uint256 deadline;
        uint256 totalContributions;
        CampaignStatus status;
        address creator;
    }

    enum CampaignStatus { ACTIVE, DELETED, SUCCESSFUL, UNSUCCEEDED }

    function createCampaign(string memory _title, string memory _description, uint256 _goal, uint256 _deadline) public nonReentrant {
        require(_goal > 0, "Goal must be greater than 0");
        require(_deadline > block.timestamp, "Deadline must be in the future");

        campaignCounter = campaignCounter + 1;

        Campaign storage newCampaign = campaigns[campaignCounter];
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.goal = _goal;
        newCampaign.deadline = _deadline;
        newCampaign.totalContributions = 0;
        newCampaign.status = CampaignStatus.ACTIVE;
        newCampaign.creator = msg.sender;

        emit CampaignStatusChanged(campaignCounter, CampaignStatus.ACTIVE);
    }

    function contribute(uint256 campaignId) external payable nonReentrant {
        require(campaignId <= campaignCounter && campaignId > 0, "Invalid campaign ID");
        require(msg.value > 0, "Contribution amount must be greater than zero");

        Campaign storage campaign = campaigns[campaignId];
        require(campaign.status == CampaignStatus.ACTIVE, "Campaign is not active");

        campaign.totalContributions = campaign.totalContributions + msg.value;
        campaign.contributions[msg.sender] = campaign.contributions[msg.sender] + msg.value;

        emit ContributionMade(campaignId, msg.sender, msg.value);
    }

    function deleteCampaign(uint256 campaignId) public nonReentrant {
        require(campaignId <= campaignCounter && campaignId > 0, "Invalid campaign ID");

        Campaign storage campaign = campaigns[campaignId];
        require(msg.sender == campaign.creator, "Only the creator can delete this campaign");
        require(campaign.status != CampaignStatus.DELETED && campaign.status != CampaignStatus.SUCCESSFUL && campaign.status != CampaignStatus.UNSUCCEEDED, "Campaign cannot be deleted");

        campaign.status = CampaignStatus.DELETED;

        emit CampaignStatusChanged(campaignId, CampaignStatus.DELETED);
    }

    function getCampaign(uint256 campaignId) public view returns (string memory, string memory, uint256, uint256, uint256, CampaignStatus) {
        require(campaignId <= campaignCounter && campaignId > 0, "Invalid campaign ID");

        Campaign storage campaign = campaigns[campaignId];
        return (campaign.title, campaign.description, campaign.goal, campaign.deadline, campaign.totalContributions, campaign.status);
    }

    function getAllCampaigns() public view returns (uint256[] memory, string[] memory, string[] memory, uint256[] memory, uint256[] memory, uint256[] memory, CampaignStatus[] memory) {
        uint256 totalCampaigns = campaignCounter;
        uint256[] memory ids = new uint256[](totalCampaigns);
        string[] memory titles = new string[](totalCampaigns);
        string[] memory descriptions = new string[](totalCampaigns);
        uint256[] memory goals = new uint256[](totalCampaigns);
        uint256[] memory deadlines = new uint256[](totalCampaigns);
        uint256[] memory totalContributions = new uint256[](totalCampaigns);
        CampaignStatus[] memory statuses = new CampaignStatus[](totalCampaigns);

        for (uint256 i = 1; i <= totalCampaigns; i++) {
            Campaign storage campaign = campaigns[i];
            ids[i - 1] = i;
            titles[i - 1] = campaign.title;
            descriptions[i - 1] = campaign.description;
            goals[i - 1] = campaign.goal;
            deadlines[i - 1] = campaign.deadline;
            totalContributions[i - 1] = campaign.totalContributions;
            statuses[i - 1] = campaign.status;
        }

        return (ids, titles, descriptions, goals, deadlines, totalContributions, statuses);
    }

    function getTotalContributions(uint256 campaignId) public view returns (uint256) {
        require(campaignId <= campaignCounter && campaignId > 0, "Invalid campaign ID");

        Campaign storage campaign = campaigns[campaignId];
        uint256 totalContributions = campaign.totalContributions;

        return totalContributions;
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getLatestCampaigns() public view returns (CampaignView[] memory) {
        uint256 totalCampaigns = campaignCounter;
        uint256 numCampaignsToReturn = totalCampaigns < 4 ? totalCampaigns : 4;

        CampaignView[] memory latestCampaigns = new CampaignView[](numCampaignsToReturn);

        for (uint256 i = 0; i < numCampaignsToReturn; i = i + 1) {
            uint256 index = totalCampaigns - numCampaignsToReturn + i + 1;
            Campaign storage campaign = campaigns[index];

            latestCampaigns[i] = CampaignView({
                title: campaign.title,
                description: campaign.description,
                goal: campaign.goal,
                deadline: campaign.deadline,
                totalContributions: campaign.totalContributions,
                status: campaign.status,
                creator: campaign.creator
            });
        }

        return latestCampaigns;
    }
}