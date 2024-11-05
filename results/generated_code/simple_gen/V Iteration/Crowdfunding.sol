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
    mapping(uint256 => mapping(address => uint256)) public contributions;
    mapping(uint256 => address[]) public contributors;

    event CampaignCreated(uint256 campaignId, address creator, string title, uint256 goal, uint256 deadline);
    event ContributionMade(uint256 campaignId, address contributor, uint256 amount);
    event CampaignDeleted(uint256 campaignId);
    event CampaignStatusChanged(uint256 campaignId, CampaignStatus status);

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

    constructor() {
        owner = msg.sender;
        campaignCounter = 0;
    }

    function createCampaign(string memory _title, string memory _description, uint256 _goal, uint256 _deadline) public {
        require(_deadline > block.timestamp, "Deadline must be in the future");
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

    function contribute(uint256 _campaignId) public payable nonReentrant {
        require(_campaignId < campaigns.length, "Campaign does not exist");
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.status == CampaignStatus.ACTIVE, "Campaign is not active");
        require(block.timestamp < campaign.deadline, "Campaign has ended");

        campaign.fundsRaised += msg.value;
        if (contributions[_campaignId][msg.sender] == 0) {
            contributors[_campaignId].push(msg.sender);
        }
        contributions[_campaignId][msg.sender] += msg.value;
        emit ContributionMade(_campaignId, msg.sender, msg.value);

        if (campaign.fundsRaised >= campaign.goal) {
            campaign.status = CampaignStatus.SUCCESSFUL;
            emit CampaignStatusChanged(_campaignId, CampaignStatus.SUCCESSFUL);
        }
    }

    function deleteCampaign(uint256 _campaignId) public nonReentrant {
        require(_campaignId < campaigns.length, "Campaign does not exist");
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.creator, "Only the campaign creator can delete this campaign");
        require(campaign.status == CampaignStatus.ACTIVE, "Campaign is not active");

        for (uint256 i = 0; i < contributors[_campaignId].length; i++) {
            address contributor = contributors[_campaignId][i];
            uint256 refundAmount = contributions[_campaignId][contributor];
            if (refundAmount > 0) {
                contributions[_campaignId][contributor] = 0;
                payable(contributor).transfer(refundAmount);
            }
        }

        campaign.status = CampaignStatus.DELETED;
        emit CampaignDeleted(_campaignId);
        emit CampaignStatusChanged(_campaignId, CampaignStatus.DELETED);
    }

    function withdrawFunds(uint256 _campaignId) public nonReentrant {
        require(_campaignId < campaigns.length, "Campaign does not exist");
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.creator, "Only the campaign creator can withdraw funds");
        require(campaign.status == CampaignStatus.SUCCESSFUL, "Campaign is not successful");

        uint256 amount = campaign.fundsRaised;
        campaign.fundsRaised = 0;
        campaign.creator.transfer(amount);
    }

    function refundContributors(uint256 _campaignId) public nonReentrant {
        require(_campaignId < campaigns.length, "Campaign does not exist");
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp > campaign.deadline, "Campaign is still active");
        require(campaign.status == CampaignStatus.UNSUCCEEDED, "Campaign is not unsuccessful");

        for (uint256 i = 0; i < contributors[_campaignId].length; i++) {
            address contributor = contributors[_campaignId][i];
            uint256 refundAmount = contributions[_campaignId][contributor];
            if (refundAmount > 0) {
                contributions[_campaignId][contributor] = 0;
                payable(contributor).transfer(refundAmount);
            }
        }
    }

    function updateCampaignStatus(uint256 _campaignId) public {
        require(_campaignId < campaigns.length, "Campaign does not exist");
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp > campaign.deadline, "Campaign is still active");

        if (campaign.fundsRaised < campaign.goal) {
            campaign.status = CampaignStatus.UNSUCCEEDED;
            emit CampaignStatusChanged(_campaignId, CampaignStatus.UNSUCCEEDED);
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
        require(_campaignId < campaigns.length, "Campaign does not exist");
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
        address[] memory _creators = new address[](length);
        string[] memory _titles = new string[](length);
        string[] memory _descriptions = new string[](length);
        uint256[] memory _goals = new uint256[](length);
        uint256[] memory _deadlines = new uint256[](length);
        uint256[] memory _fundsRaised = new uint256[](length);
        CampaignStatus[] memory _statuses = new CampaignStatus[](length);

        for (uint256 i = 0; i < length; i++) {
            Campaign storage campaign = campaigns[i];
            _creators[i] = campaign.creator;
            _titles[i] = campaign.title;
            _descriptions[i] = campaign.description;
            _goals[i] = campaign.goal;
            _deadlines[i] = campaign.deadline;
            _fundsRaised[i] = campaign.fundsRaised;
            _statuses[i] = campaign.status;
        }

        return (_creators, _titles, _descriptions, _goals, _deadlines, _fundsRaised, _statuses);
    }

    function getTotalContributions(uint256 _campaignId) public view returns (uint256) {
        require(_campaignId < campaigns.length, "Campaign does not exist");
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
        address[] memory _creators = new address[](count);
        string[] memory _titles = new string[](count);
        string[] memory _descriptions = new string[](count);
        uint256[] memory _goals = new uint256[](count);
        uint256[] memory _deadlines = new uint256[](count);
        uint256[] memory _fundsRaised = new uint256[](count);
        CampaignStatus[] memory _statuses = new CampaignStatus[](count);

        for (uint256 i = 0; i < count; i++) {
            Campaign storage campaign = campaigns[campaigns.length - 1 - i];
            _creators[i] = campaign.creator;
            _titles[i] = campaign.title;
            _descriptions[i] = campaign.description;
            _goals[i] = campaign.goal;
            _deadlines[i] = campaign.deadline;
            _fundsRaised[i] = campaign.fundsRaised;
            _statuses[i] = campaign.status;
        }

        return (_creators, _titles, _descriptions, _goals, _deadlines, _fundsRaised, _statuses);
    }
}