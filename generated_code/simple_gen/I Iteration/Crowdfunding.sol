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
        mapping(address => uint256) contributions;
        address[] contributors;
    }

    enum CampaignStatus { ACTIVE, DELETED, SUCCESSFUL, UNSUCCEEDED }

    mapping(uint256 => Campaign) private campaigns;
    uint256[] private campaignIds;

    event CampaignCreated(uint256 id, address creator, string title, uint256 goal, uint256 deadline);
    event ContributionMade(uint256 id, address contributor, uint256 amount);
    event CampaignDeleted(uint256 id);
    event CampaignStatusChanged(uint256 id, CampaignStatus status);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier nonReentrant() {
        require(!reentrancyLock, "Reentrant call detected");
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    constructor() public {
        owner = msg.sender;
        campaignCounter = 0;
    }

    function createCampaign(string memory _title, string memory _description, uint256 _goal, uint256 _deadline) public {
        require(_goal > 0, "Goal should be greater than zero");
        require(_deadline > block.timestamp, "Deadline should be in the future");
        campaignCounter++;
        Campaign storage newCampaign = campaigns[campaignCounter];
        newCampaign.id = campaignCounter;
        newCampaign.creator = payable(msg.sender); // Explicitly cast msg.sender to address payable
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.goal = _goal;
        newCampaign.deadline = _deadline;
        newCampaign.fundsRaised = 0;
        newCampaign.status = CampaignStatus.ACTIVE;
        campaignIds.push(campaignCounter);
        emit CampaignCreated(campaignCounter, msg.sender, _title, _goal, _deadline);
    }

    function contribute(uint256 _campaignId) public payable nonReentrant {
        require(msg.value > 0, "Contribution must be greater than zero");
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.status == CampaignStatus.ACTIVE, "Campaign is not active");
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(campaign.fundsRaised < campaign.goal, "Campaign has already reached its goal");
        campaign.fundsRaised += msg.value;
        if (campaign.contributions[msg.sender] == 0) {
            campaign.contributors.push(msg.sender);
        }
        campaign.contributions[msg.sender] += msg.value;
        emit ContributionMade(_campaignId, msg.sender, msg.value);
    }

    function deleteCampaign(uint256 _campaignId) public nonReentrant {
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.creator, "Only the campaign creator can delete the campaign");
        require(campaign.status == CampaignStatus.ACTIVE, "Campaign is not active");
        require(block.timestamp < campaign.deadline, "Cannot delete a campaign that has ended");
        campaign.status = CampaignStatus.DELETED;
        for (uint256 i = 0; i < campaign.contributors.length; i++) {
            address contributor = campaign.contributors[i];
            uint256 amount = campaign.contributions[contributor];
            if (amount > 0) {
                campaign.contributions[contributor] = 0;
                payable(contributor).transfer(amount);
            }
        }
        emit CampaignDeleted(_campaignId);
        emit CampaignStatusChanged(_campaignId, CampaignStatus.DELETED);
    }

    function getCampaign(uint256 _campaignId) public view returns (
        uint256 id,
        address creator,
        string memory title,
        string memory description,
        uint256 goal,
        uint256 deadline,
        uint256 fundsRaised,
        CampaignStatus status,
        address[] memory contributors
    ) {
        Campaign storage campaign = campaigns[_campaignId];
        return (
            campaign.id,
            campaign.creator,
            campaign.title,
            campaign.description,
            campaign.goal,
            campaign.deadline,
            campaign.fundsRaised,
            campaign.status,
            campaign.contributors
        );
    }

    function getAllCampaigns() public view returns (uint256[] memory) {
        return campaignIds;
    }

    function getTotalContributions(uint256 _campaignId) public view returns (uint256) {
        return campaigns[_campaignId].fundsRaised;
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getLatestCampaigns() public view returns (uint256[] memory) {
        uint256 count = campaignIds.length > 4 ? 4 : campaignIds.length;
        uint256[] memory latestCampaigns = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            latestCampaigns[i] = campaignIds[campaignIds.length - 1 - i];
        }
        return latestCampaigns;
    }
}