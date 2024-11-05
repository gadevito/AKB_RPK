pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract TokenPlatform is ERC1155, Pausable, Ownable {
    address public usdcToken;
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

    struct Batch {
        uint256 id;
        uint256 creationTime;
        string[] cids;
        address[] producers;
    }

    mapping(uint256 => Batch) public batches;
    mapping(uint256 => bool) public redeemedTokens;
    uint256 public batchCounter;

    event BaseURISet(string newBaseURI);
    event PlatformSharePercentageUpdated(uint256 newSharePercentage);
    event PriceFloorUpdated(uint256 newPriceFloor);
    event BasePriceUpdated(uint256 newBasePrice);
    event BatchSizeUpdated(uint256 newBatchSize);
    event AuctionTimeThresholdsUpdated(uint256 newIncreaseThreshold, uint256 newDecreaseThreshold);
    event BatchCreated(uint256 batchId, uint256 creationTime);

    constructor(address _usdcToken) ERC1155("") {
        usdcToken = _usdcToken;
        platformSharePercentage = 10;
        batchSize = 100;
        basePrice = 1 ether;
        priceFloor = 0.1 ether;
        priceDelta = 0.05 ether;
        priceDecreaseRate = 1 hours;
        auctionIncreaseThreshold = 1 hours;
        auctionDecreaseThreshold = 2 hours;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        uint256 batchId = tokenId / batchSize;
        uint256 indexInBatch = tokenId % batchSize;
        return string(abi.encodePacked(baseURI, batches[batchId].cids[indexInBatch]));
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setPlatformSharePercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "Percentage must be between 0 and 100");
        platformSharePercentage = _percentage;
        emit PlatformSharePercentageUpdated(_percentage);
    }

    function setPriceFloor(uint256 _priceFloor) external onlyOwner {
        require(_priceFloor > 0, "Price floor must be greater than 0");
        priceFloor = _priceFloor;
        emit PriceFloorUpdated(_priceFloor);
    }

    function setBasePrice(uint256 _basePrice) external onlyOwner {
        require(_basePrice > 0, "Base price must be greater than 0");
        basePrice = _basePrice;
        emit BasePriceUpdated(_basePrice);
    }

    function setBatchSize(uint256 _batchSize) external onlyOwner {
        require(_batchSize > 0, "Batch size must be greater than 0");
        batchSize = _batchSize;
        emit BatchSizeUpdated(_batchSize);
    }

    function setAuctionTimeThresholds(uint256 _increaseThreshold, uint256 _decreaseThreshold) external onlyOwner {
        require(_increaseThreshold > 0, "Increase threshold must be greater than 0");
        require(_decreaseThreshold > _increaseThreshold, "Decrease threshold must be greater than increase threshold");
        auctionIncreaseThreshold = _increaseThreshold;
        auctionDecreaseThreshold = _decreaseThreshold;
        emit AuctionTimeThresholdsUpdated(_increaseThreshold, _decreaseThreshold);
    }

    function mintBatch(address[] memory _producers, string[] memory _cids) external onlyOwner whenNotPaused {
        require(_producers.length == _cids.length, "Producers and CIDs length mismatch");
        require(_producers.length <= batchSize, "Batch size exceeds maximum");

        uint256 batchId = batchCounter++;
        batches[batchId] = Batch(batchId, block.timestamp, _cids, _producers);
        lastBatchCreationTime = block.timestamp;

        emit BatchCreated(batchId, block.timestamp);
    }

    function getCurrentBatchPrice() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - lastBatchCreationTime;
        uint256 priceDecrease = (timeElapsed / priceDecreaseRate) * priceDelta;
        uint256 currentPrice = basePrice > priceDecrease ? basePrice - priceDecrease : priceFloor;
        return currentPrice > priceFloor ? currentPrice : priceFloor;
    }

    function updateBasePrice() internal {
        uint256 timeElapsed = block.timestamp - lastBatchCreationTime;
        if (timeElapsed < auctionIncreaseThreshold) {
            basePrice += priceDelta;
        } else if (timeElapsed > auctionDecreaseThreshold) {
            basePrice = basePrice > priceDelta ? basePrice - priceDelta : priceFloor;
        }
        basePrice = basePrice > priceFloor ? basePrice : priceFloor;
    }

    function getBatchInfo(uint256 batchId) external view returns (Batch memory) {
        return batches[batchId];
    }

    function redeemToken(uint256 tokenId) external {
        require(!redeemedTokens[tokenId], "Token already redeemed");
        uint256 batchId = tokenId / batchSize;
        uint256 indexInBatch = tokenId % batchSize;
        require(msg.sender == batches[batchId].producers[indexInBatch], "Only producer can redeem token");
        redeemedTokens[tokenId] = true;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override whenNotPaused {
        for (uint256 i = 0; i < ids.length; ++i) {
            require(!redeemedTokens[ids[i]], "Redeemed tokens cannot be transferred");
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