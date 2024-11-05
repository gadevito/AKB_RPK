pragma solidity >=0.4.22 <0.9.0;

contract Crowdfunding {
    address public owner;
    uint256 private campaignCounter;
    bool private reentrancyLock;

    enum CampaignStatus { ACTIVE, DELETED, SUCCESSFUL, UNSUCCEEDED }

    struct Campaign {
        address payable creator;
        string title;
        string description;
        uint256 goal;
        uint256 deadline;
        uint256 fundsRaised;
        CampaignStatus status;
    }

    Campaign[] public campaigns;

    event CampaignCreated(uint256 campaignId, address creator, string title, uint256 goal, uint256 deadline);
    event ContributionMade(uint256 campaignId, address contributor, uint256 amount);
    event CampaignDeleted(uint256 campaignId);
    event CampaignStatusChanged(uint256 campaignId, CampaignStatus status);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
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
        campaigns.push(Campaign({
            creator: payable(msg.sender),
            title: _title,
            description: _description,
            goal: _goal,
            deadline: _deadline,
            fundsRaised: 0,
            status: CampaignStatus.ACTIVE
        }));
        campaignCounter++;
        emit CampaignCreated(campaignCounter - 1, msg.sender, _title, _goal, _deadline);
    }

    function contribute(uint256 _campaignId) public payable noReentrancy {
        require(_campaignId < campaigns.length, "Invalid campaign ID");
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.status == CampaignStatus.ACTIVE, "Campaign is not active");
        require(block.timestamp < campaign.deadline, "Campaign deadline has passed");

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

    function getCampaign(uint256 _campaignId) public view returns (Campaign memory) {
        require(_campaignId < campaigns.length, "Invalid campaign ID");
        return campaigns[_campaignId];
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