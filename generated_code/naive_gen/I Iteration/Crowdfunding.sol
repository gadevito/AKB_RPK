pragma solidity >=0.4.22 <0.9.0;

contract Crowdfunding {
    address public owner;
    uint256 private campaignCounter;
    bool private reentrancyLock;

    struct Campaign {
        uint256 id;
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

    event CampaignCreated(uint256 id, address creator, string title, uint256 goal, uint256 deadline);
    event ContributionMade(uint256 id, address contributor, uint256 amount);
    event CampaignDeleted(uint256 id);
    event CampaignStatusChanged(uint256 id, CampaignStatus status);

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
    }

    function createCampaign(string memory _title, string memory _description, uint256 _goal, uint256 _deadline) public {
        require(_deadline > block.timestamp, "Deadline should be in the future");
        campaignCounter++;
        campaigns.push(Campaign({
            id: campaignCounter,
            creator: payable(msg.sender),
            title: _title,
            description: _description,
            goal: _goal,
            deadline: _deadline,
            fundsRaised: 0,
            status: CampaignStatus.ACTIVE
        }));
        emit CampaignCreated(campaignCounter, msg.sender, _title, _goal, _deadline);
    }

    function contribute(uint256 _campaignId) public payable noReentrancy {
        require(_campaignId > 0 && _campaignId <= campaignCounter, "Invalid campaign ID");
        Campaign storage campaign = campaigns[_campaignId - 1];
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
        require(_campaignId > 0 && _campaignId <= campaignCounter, "Invalid campaign ID");
        Campaign storage campaign = campaigns[_campaignId - 1];
        require(campaign.creator == msg.sender, "Only the campaign creator can delete this campaign");
        require(campaign.status == CampaignStatus.ACTIVE, "Campaign is not active");

        campaign.status = CampaignStatus.DELETED;
        emit CampaignDeleted(_campaignId);
        emit CampaignStatusChanged(_campaignId, CampaignStatus.DELETED);
    }

    function getCampaign(uint256 _campaignId) public view returns (uint256, address, string memory, string memory, uint256, uint256, uint256, CampaignStatus) {
        require(_campaignId > 0 && _campaignId <= campaignCounter, "Invalid campaign ID");
        Campaign storage campaign = campaigns[_campaignId - 1];
        return (campaign.id, campaign.creator, campaign.title, campaign.description, campaign.goal, campaign.deadline, campaign.fundsRaised, campaign.status);
    }

    function getAllCampaigns() public view returns (Campaign[] memory) {
        return campaigns;
    }

    function getTotalContributions(uint256 _campaignId) public view returns (uint256) {
        require(_campaignId > 0 && _campaignId <= campaignCounter, "Invalid campaign ID");
        return campaigns[_campaignId - 1].fundsRaised;
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getLatestCampaigns() public view returns (Campaign[] memory) {
        uint256 count = campaignCounter > 4 ? 4 : campaignCounter;
        Campaign[] memory latestCampaigns = new Campaign[](count);
        for (uint256 i = 0; i < count; i++) {
            latestCampaigns[i] = campaigns[campaignCounter - 1 - i];
        }
        return latestCampaigns;
    }
}