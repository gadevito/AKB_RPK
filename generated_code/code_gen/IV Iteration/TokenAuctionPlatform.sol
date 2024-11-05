pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenAuctionPlatform is ERC1155, Pausable, Ownable {
    address public usdcTokenAddress;
    string public baseURI;
    uint8 public platformSharePercentage;
    uint256 public batchSize;
    uint256 public basePrice;
    uint256 public priceFloor;
    uint256 public priceDelta;
    uint256 public priceDecreaseRate;
    uint256 public auctionIncreaseThreshold;
    uint256 public auctionDecreaseThreshold;
    uint256 public batchCounter;

    mapping(uint256 => Batch) public batches;
    mapping(uint256 => bool) public tokenRedemptionStatus;
    mapping(uint256 => address) public tokenProducers;

    event BaseURIUpdated(string newBaseURI);
    event PlatformSharePercentageUpdated(uint8 newSharePercentage);
    event PriceFloorUpdated(uint256 newPriceFloor);
    event BasePriceUpdated(uint256 newBasePrice);
    event BatchSizeUpdated(uint256 newBatchSize);
    event AuctionTimeThresholdsUpdated(uint256 newIncreaseThreshold, uint256 newDecreaseThreshold);
    event BatchMinted(uint256 batchId, uint256 creationTime);
    event TokenRedeemed(uint256 tokenId, address producer);

    constructor(
        address _owner,
        address _usdcTokenAddress,
        uint8 _platformSharePercentage,
        uint256 _batchSize,
        uint256 _basePrice,
        uint256 _priceFloor,
        uint256 _priceDelta,
        uint256 _priceDecreaseRate,
        uint256 _auctionIncreaseThreshold,
        uint256 _auctionDecreaseThreshold
    ) ERC1155("") {
        transferOwnership(_owner);
        usdcTokenAddress = _usdcTokenAddress;
        platformSharePercentage = _platformSharePercentage;
        batchSize = _batchSize;
        basePrice = _basePrice;
        priceFloor = _priceFloor;
        priceDelta = _priceDelta;
        priceDecreaseRate = _priceDecreaseRate;
        auctionIncreaseThreshold = _auctionIncreaseThreshold;
        auctionDecreaseThreshold = _auctionDecreaseThreshold;
    }

    struct Batch {
        address[] producers;
        string[] metadataCIDs;
        uint256 creationTime;
    }

function setBaseURI(string memory _newBaseURI) public onlyOwner {
    require(bytes(_newBaseURI).length > 0, "New base URI cannot be empty");
    if (keccak256(bytes(_newBaseURI)) != keccak256(bytes(baseURI))) {
        baseURI = _newBaseURI;
        emit BaseURIUpdated(_newBaseURI);
    }
}


function pause() public onlyOwner whenNotPaused {
    _pause();
    emit Paused(msg.sender);
}


function unpause() public onlyOwner whenPaused {
    _unpause();
    emit Unpaused(msg.sender);
}


function setPlatformSharePercentage(uint8 _newSharePercentage) public onlyOwner {
    require(_newSharePercentage <= 100, "Share percentage must be between 0 and 100");

    platformSharePercentage = _newSharePercentage;

    emit PlatformSharePercentageUpdated(_newSharePercentage);
}


function setPriceFloor(uint256 _newPriceFloor) external onlyOwner {
    require(_newPriceFloor > 0, "Price floor must be greater than 0");

    priceFloor = _newPriceFloor;

    emit PriceFloorUpdated(_newPriceFloor);
}


function setBasePrice(uint256 _newBasePrice) external onlyOwner {
    require(_newBasePrice > 0, "Base price must be greater than 0");

    basePrice = _newBasePrice;

    emit BasePriceUpdated(_newBasePrice);
}


function setBatchSize(uint256 _batchSize) external onlyOwner {
    require(_batchSize > 0, "Batch size must be greater than 0");

    batchSize = _batchSize;

    emit BatchSizeUpdated(_batchSize);
}


function setAuctionTimeThresholds(uint256 newIncreaseThreshold, uint256 newDecreaseThreshold) external onlyOwner {
    require(newIncreaseThreshold > 0, "Increase threshold must be greater than 0");
    require(newDecreaseThreshold > newIncreaseThreshold, "Decrease threshold must be greater than increase threshold");

    auctionIncreaseThreshold = newIncreaseThreshold;
    auctionDecreaseThreshold = newDecreaseThreshold;

    emit AuctionTimeThresholdsUpdated(newIncreaseThreshold, newDecreaseThreshold);
}


function mintBatch(address[] calldata producers, string[] calldata metadataCIDs) external onlyOwner whenNotPaused {
    require(producers.length == metadataCIDs.length, "Producers and metadataCIDs length mismatch");
    require(producers.length <= batchSize, "Batch size exceeds maximum allowed");

    batchCounter = batchCounter + 1;
    uint256 newBatchId = batchCounter;

    Batch storage newBatch = batches[newBatchId];
    for (uint256 i = 0; i < producers.length; i = i + 1) {
        newBatch.producers.push(producers[i]);
        newBatch.metadataCIDs.push(metadataCIDs[i]);
    }

    newBatch.creationTime = block.timestamp;

    emit BatchMinted(newBatchId, block.timestamp);

    // Update basePrice based on the duration of the last batch sale
    // Assuming there's a logic to calculate the new base price based on the last batch sale duration
    // This part of the logic is not provided in the specification, so it's left as a placeholder
    // basePrice = calculateNewBasePrice();
}


function getBatchPrice(uint256 batchId) public view returns (uint256) {
    // Ensure the batchId exists in the batches mapping
    Batch storage batch = batches[batchId];
    require(batch.creationTime != 0, "Batch does not exist");

    // Retrieve the batch creation time
    uint256 creationTime = batch.creationTime;

    // Calculate the time elapsed since the batch creation
    uint256 timeElapsed = block.timestamp - creationTime;

    // Compute the price decrease based on the elapsed time and the priceDecreaseRate
    uint256 priceDecrease = timeElapsed * priceDecreaseRate;

    // Calculate the current price by subtracting the price decrease from the basePrice
    uint256 currentPrice = basePrice;
    if (priceDecrease < currentPrice) {
        currentPrice = currentPrice - priceDecrease;
    } else {
        currentPrice = 0;
    }

    // Ensure the current price does not fall below the priceFloor
    if (currentPrice < priceFloor) {
        currentPrice = priceFloor;
    }

    // Return the calculated current price
    return currentPrice;
}


function getBatchInfo(uint256 batchId) public view returns (Batch memory) {
    Batch storage batch = batches[batchId];
    require(batch.creationTime != 0, "Batch does not exist");
    return batch;
}


function redeemToken(uint256 tokenId) external {
    // Check if the token has already been redeemed
    bool isRedeemed = tokenRedemptionStatus[tokenId];
    require(!isRedeemed, "Token has already been redeemed");

    // Ensure the caller is the producer associated with the token
    address producer = tokenProducers[tokenId];
    require(msg.sender == producer, "Caller is not the producer associated with the token");

    // Mark the token as redeemed
    tokenRedemptionStatus[tokenId] = true;

    // Emit the TokenRedeemed event
    emit TokenRedeemed(tokenId, msg.sender);
}


}