pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenAuctionPlatform is ERC1155, Pausable, Ownable {
    address public usdcToken;
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

    struct Batch {
        uint256 creationTime;
        address[] producers;
        string[] metadataCIDs;
    }

    mapping(uint256 => Batch) public batches;
    mapping(uint256 => bool) public tokenRedemptionStatus;
    mapping(uint256 => address) public tokenProducers;

    event BaseURIUpdated(string newBaseURI);
    event PlatformSharePercentageUpdated(uint8 newSharePercentage);
    event PriceFloorUpdated(uint256 newPriceFloor);
    event BasePriceUpdated(uint256 newBasePrice);
    event BatchCreated(uint256 batchId, uint256 creationTime);
    event BatchSizeUpdated(uint256 newBatchSize);
    event AuctionTimeThresholdsUpdated(uint256 newAuctionIncreaseThreshold, uint256 newAuctionDecreaseThreshold);
    event TokenRedeemed(uint256 tokenId, address redeemer);

    constructor(address _owner, address _usdcToken) ERC1155("") {
        transferOwnership(_owner);
        usdcToken = _usdcToken;
        platformSharePercentage = 10;
        batchSize = 100;
        basePrice = 1 ether;
        priceFloor = 0.1 ether;
        priceDelta = 0.01 ether;
        priceDecreaseRate = 0.001 ether;
        auctionIncreaseThreshold = 1 hours;
        auctionDecreaseThreshold = 2 hours;
        batchCounter = 0;
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

    function setPlatformSharePercentage(uint8 newSharePercentage) external onlyOwner {
        require(newSharePercentage <= 100, "Share percentage must be between 0 and 100");

        platformSharePercentage = newSharePercentage;

        emit PlatformSharePercentageUpdated(newSharePercentage);
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

    function setAuctionTimeThresholds(uint256 _auctionIncreaseThreshold, uint256 _auctionDecreaseThreshold) external onlyOwner {
        require(_auctionIncreaseThreshold > 0, "Auction increase threshold must be greater than 0");
        require(_auctionDecreaseThreshold > _auctionIncreaseThreshold, "Auction decrease threshold must be greater than increase threshold");

        auctionIncreaseThreshold = _auctionIncreaseThreshold;
        auctionDecreaseThreshold = _auctionDecreaseThreshold;

        emit AuctionTimeThresholdsUpdated(_auctionIncreaseThreshold, _auctionDecreaseThreshold);
    }

    function mintBatch(address[] calldata producers, string[] calldata metadataCIDs) external onlyOwner whenNotPaused {
        require(producers.length == metadataCIDs.length, "Producers and metadataCIDs length mismatch");
        require(producers.length <= batchSize, "Batch size exceeds maximum allowed");

        batchCounter = batchCounter + 1;
        uint256 newBatchId = batchCounter;

        Batch storage newBatch = batches[newBatchId];
        newBatch.creationTime = block.timestamp;

        for (uint256 i = 0; i < producers.length; i = i + 1) {
            newBatch.producers.push(producers[i]);
            newBatch.metadataCIDs.push(metadataCIDs[i]);
        }

        emit BatchCreated(newBatchId, block.timestamp);

        // Update basePrice based on the duration of the last batch sale
        // Assuming there is a logic to calculate the new base price based on the last batch sale duration
        // This part of the logic is not provided in the specification, so it is left as a placeholder
        // basePrice = calculateNewBasePrice();
    }

    function getBatchPrice(uint256 batchId) public view returns (uint256) {
        // Ensure the batchId exists in the batches mapping
        Batch storage batch = batches[batchId];
        require(batch.creationTime != 0, "Batch does not exist");

        // Retrieve the batch creation time
        uint256 creationTime = batch.creationTime;

        // Calculate the time elapsed since the batch creation
        uint256 elapsedTime = block.timestamp - creationTime;

        // Calculate the price decrease based on the elapsed time and the priceDecreaseRate
        uint256 priceDecrease = elapsedTime * priceDecreaseRate;

        // Subtract the calculated price decrease from the basePrice
        uint256 currentPrice = basePrice;
        if (priceDecrease < currentPrice) {
            currentPrice = currentPrice - priceDecrease;
        } else {
            currentPrice = 0;
        }

        // Ensure the resulting price does not fall below the priceFloor
        if (currentPrice < priceFloor) {
            currentPrice = priceFloor;
        }

        // Return the calculated price
        return currentPrice;
    }

    function getBatchInfo(uint256 batchId) public view returns (address[] memory producers, string[] memory metadataCIDs, uint256 creationTime) {
        // Ensure the batchId exists in the batches mapping
        require(batches[batchId].creationTime != 0, "Batch does not exist");

        // Retrieve the batch information
        Batch storage batch = batches[batchId];
        address[] memory batchProducers = batch.producers;
        string[] memory batchMetadataCIDs = batch.metadataCIDs;
        uint256 batchCreationTime = batch.creationTime;

        // Return the batch information
        return (batchProducers, batchMetadataCIDs, batchCreationTime);
    }

    function redeemToken(uint256 tokenId) external {
        require(!paused(), "Contract is paused");

        bool isRedeemed = tokenRedemptionStatus[tokenId];
        require(!isRedeemed, "Token already redeemed");

        address producer = tokenProducers[tokenId];
        require(msg.sender == producer, "Caller is not the producer");

        tokenRedemptionStatus[tokenId] = true;

        emit TokenRedeemed(tokenId, msg.sender);
    }
}