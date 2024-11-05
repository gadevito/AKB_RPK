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
        mapping(address => uint256) contributions;
        address[] contributors;
    }

    enum CampaignStatus { ACTIVE, DELETED, SUCCESSFUL, UNSUCCEEDED }

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
        Campaign storage newCampaign = campaigns.push();
        newCampaign.creator = payable(msg.sender);
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.goal = _goal;
        newCampaign.deadline = _deadline;
        newCampaign.fundsRaised = 0;
        newCampaign.status = CampaignStatus.ACTIVE;
        emit CampaignCreated(campaignCounter, msg.sender, _title, _goal, _deadline);
        campaignCounter++;
    }

    function contribute(uint256 _campaignId) public payable noReentrancy {
        require(_campaignId < campaigns.length, "Invalid campaign ID");
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.status == CampaignStatus.ACTIVE, "Campaign is not active");
        require(block.timestamp < campaign.deadline, "Campaign deadline has passed");

        if (campaign.contributions[msg.sender] == 0) {
            campaign.contributors.push(msg.sender);
        }

        campaign.fundsRaised += msg.value;
        campaign.contributions[msg.sender] += msg.value;
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

        // Refund contributors
        for (uint256 i = 0; i < campaign.contributors.length; i++) {
            address payable contributor = payable(campaign.contributors[i]);
            uint256 amount = campaign.contributions[contributor];
            if (amount > 0) {
                campaign.contributions[contributor] = 0;
                contributor.transfer(amount);
            }
        }
    }

    function getCampaign(uint256 _campaignId) public view returns (
        address creator,
        string memory title,
        string memory description,
        uint256 goal,
        uint256 deadline,
        uint256 fundsRaised,
        CampaignStatus status
    ) {
        require(_campaignId < campaigns.length, "Invalid campaign ID");
        Campaign storage campaign = campaigns[_campaignId];
        return (
            campaign.creator,
            campaign.title,
            campaign.description,
            campaign.goal,
            campaign.deadline,
            campaign.fundsRaised,
            campaign.status
        );
    }

    function getAllCampaigns() public view returns (
        address[] memory creators,
        string[] memory titles,
        string[] memory descriptions,
        uint256[] memory goals,
        uint256[] memory deadlines,
        uint256[] memory fundsRaised,
        CampaignStatus[] memory statuses
    ) {
        uint256 length = campaigns.length;
        creators = new address[](length);
        titles = new string[](length);
        descriptions = new string[](length);
        goals = new uint256[](length);
        deadlines = new uint256[](length);
        fundsRaised = new uint256[](length);
        statuses = new CampaignStatus[](length);

        for (uint256 i = 0; i < length; i++) {
            Campaign storage campaign = campaigns[i];
            creators[i] = campaign.creator;
            titles[i] = campaign.title;
            descriptions[i] = campaign.description;
            goals[i] = campaign.goal;
            deadlines[i] = campaign.deadline;
            fundsRaised[i] = campaign.fundsRaised;
            statuses[i] = campaign.status;
        }
    }

    function getTotalContributions(uint256 _campaignId) public view returns (uint256) {
        require(_campaignId < campaigns.length, "Invalid campaign ID");
        return campaigns[_campaignId].fundsRaised;
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getLatestCampaigns() public view returns (
        address[] memory creators,
        string[] memory titles,
        string[] memory descriptions,
        uint256[] memory goals,
        uint256[] memory deadlines,
        uint256[] memory fundsRaised,
        CampaignStatus[] memory statuses
    ) {
        uint256 count = campaigns.length > 4 ? 4 : campaigns.length;
        creators = new address[](count);
        titles = new string[](count);
        descriptions = new string[](count);
        goals = new uint256[](count);
        deadlines = new uint256[](count);
        fundsRaised = new uint256[](count);
        statuses = new CampaignStatus[](count);

        for (uint256 i = 0; i < count; i++) {
            Campaign storage campaign = campaigns[campaigns.length - 1 - i];
            creators[i] = campaign.creator;
            titles[i] = campaign.title;
            descriptions[i] = campaign.description;
            goals[i] = campaign.goal;
            deadlines[i] = campaign.deadline;
            fundsRaised[i] = campaign.fundsRaised;
            statuses[i] = campaign.status;
        }
    }
}