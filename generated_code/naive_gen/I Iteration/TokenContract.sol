pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

contract TokenContract is IERC1155Receiver, Ownable, Pausable, ERC165 {
    address public usdcTokenAddress;
    string public baseURI;
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
        string[] metadataCIDs;
        bool[] redeemed;
    }

    mapping(uint256 => Batch) public batches;
    uint256 public nextBatchId;

    event BaseURISet(string newBaseURI);
    event PlatformSharePercentageUpdated(uint256 newSharePercentage);
    event PriceFloorUpdated(uint256 newPriceFloor);
    event BasePriceUpdated(uint256 newBasePrice);
    event BatchSizeUpdated(uint256 newBatchSize);
    event AuctionTimeThresholdsUpdated(uint256 newIncreaseThreshold, uint256 newDecreaseThreshold);
    event BatchCreated(uint256 batchId, uint256 creationTime);
    event TokenRedeemed(uint256 batchId, uint256 tokenId);

    constructor(address _usdcTokenAddress) {
        usdcTokenAddress = _usdcTokenAddress;
        platformSharePercentage = 5;
        batchSize = 10;
        basePrice = 1000;
        priceFloor = 500;
        priceDelta = 100;
        priceDecreaseRate = 10;
        auctionIncreaseThreshold = 1 hours;
        auctionDecreaseThreshold = 2 hours;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    function uri(uint256 _tokenId) public view returns (string memory) {
        uint256 batchId = _tokenId / batchSize;
        uint256 tokenId = _tokenId % batchSize;
        return string(abi.encodePacked(baseURI, batches[batchId].metadataCIDs[tokenId]));
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

    function mintBatch(string[] memory _metadataCIDs) external onlyOwner whenNotPaused {
        require(_metadataCIDs.length <= batchSize, "Batch size exceeds maximum limit");
        uint256 batchId = nextBatchId++;
        batches[batchId] = Batch(batchId, block.timestamp, _metadataCIDs, new bool[](_metadataCIDs.length));
        lastBatchCreationTime = block.timestamp;
        emit BatchCreated(batchId, block.timestamp);
    }

    function getCurrentPrice() public view returns (uint256) {
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

    function getBatchInfo(uint256 _batchId) external view returns (Batch memory) {
        return batches[_batchId];
    }

    function redeemToken(uint256 _batchId, uint256 _tokenId) external whenNotPaused {
        require(_batchId < nextBatchId, "Invalid batch ID");
        require(_tokenId < batches[_batchId].metadataCIDs.length, "Invalid token ID");
        require(!batches[_batchId].redeemed[_tokenId], "Token already redeemed");
        batches[_batchId].redeemed[_tokenId] = true;
        emit TokenRedeemed(_batchId, _tokenId);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}