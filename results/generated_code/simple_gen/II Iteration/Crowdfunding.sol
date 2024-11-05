pragma solidity >=0.4.22 <0.9.0;

contract Crowdfunding {
    address public owner;
    uint256 private campaignCounter;
    bool private reentrancyLock;

    struct Campaign {
        address payable creator;
        string title;
        string description;
        uint256 goal;
        uint256 deadline;
        uint256 fundsRaised;
        CampaignStatus status;
    }

    enum CampaignStatus { ACTIVE, DELETED, SUCCESSFUL, UNSUCCEEDED }

    Campaign[] public campaigns;

    event CampaignCreated(uint256 campaignId, address creator, string title, uint256 goal, uint256 deadline);
    event ContributionMade(uint256 campaignId, address contributor, uint256 amount);
    event CampaignDeleted(uint256 campaignId);
    event CampaignStatusChanged(uint256 campaignId, CampaignStatus status);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier noReentrancy() {
        require(!reentrancyLock, "Reentrant call detected");
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    constructor() {
        owner = msg.sender;
        campaignCounter = 0;
        reentrancyLock = false;
    }

    function createCampaign(string memory _title, string memory _description, uint256 _goal, uint256 _deadline) public {
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(_goal > 0, "Goal must be greater than zero");

        campaigns.push(Campaign({
            creator: payable(msg.sender),
            title: _title,
            description: _description,
            goal: _goal,
            deadline: _deadline,
            fundsRaised: 0,
            status: CampaignStatus.ACTIVE
        }));

        emit CampaignCreated(campaignCounter, msg.sender, _title, _goal, _deadline);
        campaignCounter++;
    }

    function contribute(uint256 _campaignId) public payable noReentrancy {
        require(_campaignId < campaigns.length, "Invalid campaign ID");
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.status == CampaignStatus.ACTIVE, "Campaign is not active");
        require(block.timestamp < campaign.deadline, "Campaign has ended");

        campaign.fundsRaised += msg.value;
        emit ContributionMade(_campaignId, msg.sender, msg.value);

        if (campaign.fundsRaised >= campaign.goal) {
            campaign.status = CampaignStatus.SUCCESSFUL;
            emit CampaignStatusChanged(_campaignId, CampaignStatus.SUCCESSFUL);
        }
    }

    function deleteCampaign(uint256 _campaignId) public noReentrancy {
        require(_campaignId < campaigns.length, "Invalid campaign ID");
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.creator, "Only the campaign creator can delete the campaign");
        require(campaign.status == CampaignStatus.ACTIVE, "Campaign is not active");

        campaign.status = CampaignStatus.DELETED;
        emit CampaignDeleted(_campaignId);
        emit CampaignStatusChanged(_campaignId, CampaignStatus.DELETED);
    }

    function getCampaign(uint256 _campaignId) public view returns (address creator, string memory title, string memory description, uint256 goal, uint256 deadline, uint256 fundsRaised, CampaignStatus status) {
        require(_campaignId < campaigns.length, "Invalid campaign ID");
        Campaign storage campaign = campaigns[_campaignId];
        return (campaign.creator, campaign.title, campaign.description, campaign.goal, campaign.deadline, campaign.fundsRaised, campaign.status);
    }

    function getAllCampaigns() public view returns (Campaign[] memory) {
        return campaigns;
    }

    function getTotalContributions(uint256 _campaignId) public view returns (uint256) {
        require(_campaignId < campaigns.length, "Invalid campaign ID");
        return campaigns[_campaignId].fundsRaised;
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getLatestCampaigns() public view returns (Campaign[] memory) {
        uint256 count = campaigns.length > 4 ? 4 : campaigns.length;
        Campaign[] memory latestCampaigns = new Campaign[](count);
        for (uint256 i = 0; i < count; i++) {
            latestCampaigns[i] = campaigns[campaigns.length - 1 - i];
        }
        return latestCampaigns;
    }
}