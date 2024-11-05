pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

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
    uint256 private lastBatchCreationTime;
    uint256 private lastBatchSaleDuration;
    uint256 private currentBatchId;

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

    constructor(address _owner, address _usdcToken) Ownable() ERC1155("") {
        transferOwnership(_owner);
        usdcToken = _usdcToken;
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

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId));
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

    function mintBatch(address[] calldata producers, string[] calldata metadataCIDs) external onlyOwner whenNotPaused {
        require(producers.length == metadataCIDs.length, "Producers and metadataCIDs length mismatch");
        require(producers.length <= batchSize, "Batch size exceeds maximum");

        uint256 batchId = currentBatchId++;
        uint256 creationTime = block.timestamp;
        batches[batchId] = Batch(batchId, creationTime, basePrice, false);

        for (uint256 i = 0; i < producers.length; i++) {
            uint256 tokenId = batchId * batchSize + i;
            _mint(producers[i], tokenId, 1, "");
            tokenRedemptionStatus[tokenId] = false;
        }

        lastBatchCreationTime = creationTime;
        emit BatchCreated(batchId, creationTime);
    }

    function getCurrentBatchPrice(uint256 batchId) public view returns (uint256) {
        Batch memory batch = batches[batchId];
        uint256 timeElapsed = block.timestamp - batch.creationTime;
        uint256 priceDecrease = (timeElapsed * priceDelta) / priceDecreaseRate;
        uint256 currentPrice = batch.price > priceDecrease ? batch.price - priceDecrease : priceFloor;
        return currentPrice;
    }

    function updateBasePrice() internal {
        uint256 timeElapsed = block.timestamp - lastBatchCreationTime;
        if (timeElapsed >= auctionDecreaseThreshold) {
            basePrice = basePrice > priceDelta ? basePrice - priceDelta : priceFloor;
        } else if (timeElapsed >= auctionIncreaseThreshold) {
            basePrice += priceDelta;
        }
    }

    function redeemToken(uint256 tokenId) external whenNotPaused {
        require(balanceOf(msg.sender, tokenId) > 0, "Caller does not own the token");
        require(!tokenRedemptionStatus[tokenId], "Token already redeemed");

        tokenRedemptionStatus[tokenId] = true;
        _burn(msg.sender, tokenId, 1);

        uint256 rewardAmount = 100 * 10**6; // 100 USDC (assuming USDC has 6 decimals)
        require(IERC20(usdcToken).transfer(msg.sender, rewardAmount), "Reward transfer failed");
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            require(!tokenRedemptionStatus[ids[i]], "Redeemed tokens cannot be transferred");
        }
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}