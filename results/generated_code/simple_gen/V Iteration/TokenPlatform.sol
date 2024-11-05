pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TokenPlatform is ERC1155, Pausable, Ownable {
    using Strings for uint256;

    address public usdcTokenAddress;
    string private baseURI;
    uint256 public platformSharePercentage;
    uint256 public batchSize;
    uint256 public basePrice;
    uint256 public priceFloor;
    uint256 public priceDelta;
    uint256 public priceDecreaseRate;
    uint256 public auctionIncreaseThreshold;
    uint256 public auctionDecreaseThreshold;
    uint256 public lastBatchCreationTime;
    uint256 public lastBatchSaleDuration;
    uint256 public currentBatchId;

    struct Batch {
        uint256 id;
        uint256 creationTime;
        uint256 price;
        bool redeemed;
    }

    mapping(uint256 => Batch) public batches;
    mapping(uint256 => bool) public tokenRedemptionStatus;

    event BaseURISet(string newBaseURI);
    event PlatformSharePercentageUpdated(uint256 newSharePercentage);
    event PriceFloorUpdated(uint256 newPriceFloor);
    event BasePriceUpdated(uint256 newBasePrice);
    event BatchSizeUpdated(uint256 newBatchSize);
    event AuctionTimeThresholdsUpdated(uint256 newIncreaseThreshold, uint256 newDecreaseThreshold);
    event BatchCreated(uint256 batchId, uint256 creationTime);
    event TokenRedeemed(uint256 tokenId, address producer);

    constructor(address _owner, address _usdcTokenAddress) ERC1155("") {
        transferOwnership(_owner);
        usdcTokenAddress = _usdcTokenAddress;
        platformSharePercentage = 10;
        batchSize = 100;
        basePrice = 1 ether;
        priceFloor = 0.1 ether;
        priceDelta = 0.05 ether;
        priceDecreaseRate = 0.01 ether;
        auctionIncreaseThreshold = 1 hours;
        auctionDecreaseThreshold = 2 hours;
        currentBatchId = 0;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, batches[tokenId].id.toString()));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setPlatformSharePercentage(uint256 _percentage) public onlyOwner {
        require(_percentage <= 100, "Percentage must be between 0 and 100");
        platformSharePercentage = _percentage;
        emit PlatformSharePercentageUpdated(_percentage);
    }

    function setPriceFloor(uint256 _priceFloor) public onlyOwner {
        require(_priceFloor > 0, "Price floor must be greater than 0");
        priceFloor = _priceFloor;
        emit PriceFloorUpdated(_priceFloor);
    }

    function setBasePrice(uint256 _basePrice) public onlyOwner {
        require(_basePrice > 0, "Base price must be greater than 0");
        basePrice = _basePrice;
        emit BasePriceUpdated(_basePrice);
    }

    function setBatchSize(uint256 _batchSize) public onlyOwner {
        require(_batchSize > 0, "Batch size must be greater than 0");
        batchSize = _batchSize;
        emit BatchSizeUpdated(_batchSize);
    }

    function setAuctionTimeThresholds(uint256 _increaseThreshold, uint256 _decreaseThreshold) public onlyOwner {
        require(_increaseThreshold > 0, "Increase threshold must be greater than 0");
        require(_decreaseThreshold > _increaseThreshold, "Decrease threshold must be greater than increase threshold");
        auctionIncreaseThreshold = _increaseThreshold;
        auctionDecreaseThreshold = _decreaseThreshold;
        emit AuctionTimeThresholdsUpdated(_increaseThreshold, _decreaseThreshold);
    }

    function mintBatch(address[] memory producers, string[] memory metadataCIDs) public onlyOwner whenNotPaused {
        require(producers.length == metadataCIDs.length, "Producers and metadataCIDs length mismatch");
        require(producers.length <= batchSize, "Batch size exceeds maximum");

        uint256 batchId = currentBatchId++;
        uint256 creationTime = block.timestamp;
        batches[batchId] = Batch(batchId, creationTime, basePrice, false);

        for (uint256 i = 0; i < producers.length; i++) {
            _mint(producers[i], batchId, 1, abi.encodePacked(metadataCIDs[i]));
        }

        lastBatchCreationTime = creationTime;
        emit BatchCreated(batchId, creationTime);
    }

    function getCurrentBatchPrice() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - lastBatchCreationTime;
        uint256 priceDecrease = (timeElapsed / auctionDecreaseThreshold) * priceDecreaseRate;
        uint256 currentPrice = basePrice > priceDecrease ? basePrice - priceDecrease : priceFloor;
        return currentPrice;
    }

    function updateBasePrice() public onlyOwner {
        uint256 timeElapsed = block.timestamp - lastBatchCreationTime;
        if (timeElapsed < auctionIncreaseThreshold) {
            basePrice += priceDelta;
        } else if (timeElapsed > auctionDecreaseThreshold) {
            basePrice = basePrice > priceDelta ? basePrice - priceDelta : priceFloor;
        }
        basePrice = basePrice > priceFloor ? basePrice : priceFloor;
        emit BasePriceUpdated(basePrice);
    }

    function getBatchInfo(uint256 batchId) public view returns (Batch memory) {
        return batches[batchId];
    }

    function redeemToken(uint256 tokenId) public whenNotPaused {
        require(balanceOf(msg.sender, tokenId) > 0, "Caller does not own the token");
        require(!tokenRedemptionStatus[tokenId], "Token already redeemed");

        tokenRedemptionStatus[tokenId] = true;
        _burn(msg.sender, tokenId, 1);
        emit TokenRedeemed(tokenId, msg.sender);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override whenNotPaused {
        for (uint256 i = 0; i < ids.length; i++) {
            require(!tokenRedemptionStatus[ids[i]], "Token has been redeemed and cannot be transferred");
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}