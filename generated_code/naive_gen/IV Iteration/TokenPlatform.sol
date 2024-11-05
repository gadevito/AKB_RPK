pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract TokenPlatform is ERC1155, Pausable, Ownable {
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
    uint256 private lastBatchCreationTime;
    uint256 private lastBatchSaleDuration;

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
    event BatchCreated(uint256 batchId, uint256 creationTime);
    event TokenRedeemed(uint256 batchId, uint256 tokenId);

    constructor(address _usdcTokenAddress) ERC1155("") public {
        usdcTokenAddress = _usdcTokenAddress;
        platformSharePercentage = 10;
        batchSize = 10;
        basePrice = 1000;
        priceFloor = 500;
        priceDelta = 100;
        priceDecreaseRate = 10;
        auctionIncreaseThreshold = 1 hours;
        auctionDecreaseThreshold = 2 hours;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        uint256 batchId = tokenId / batchSize;
        uint256 index = tokenId % batchSize;
        return string(abi.encodePacked(baseURI, batches[batchId].metadataCIDs[index]));
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
    }

    function setAuctionTimeThresholds(uint256 _increaseThreshold, uint256 _decreaseThreshold) public onlyOwner {
        require(_increaseThreshold > 0, "Increase threshold must be greater than 0");
        require(_decreaseThreshold > _increaseThreshold, "Decrease threshold must be greater than increase threshold");
        auctionIncreaseThreshold = _increaseThreshold;
        auctionDecreaseThreshold = _decreaseThreshold;
    }

    function mintBatch(string[] memory _metadataCIDs) public onlyOwner whenNotPaused {
        require(_metadataCIDs.length <= batchSize, "Batch size exceeds maximum limit");

        uint256 batchId = nextBatchId++;
        batches[batchId] = Batch({
            id: batchId,
            creationTime: block.timestamp,
            metadataCIDs: _metadataCIDs,
            redeemed: new bool[](_metadataCIDs.length)
        });

        lastBatchCreationTime = block.timestamp;

        emit BatchCreated(batchId, block.timestamp);
    }

    function getCurrentPrice() public view returns (uint256) {
        uint256 timeElapsed = block.timestamp - lastBatchCreationTime;
        uint256 priceDecrease = (timeElapsed / priceDecreaseRate) * priceDelta;
        uint256 currentPrice = basePrice > priceDecrease ? basePrice - priceDecrease : priceFloor;
        return currentPrice;
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

    function redeemToken(uint256 batchId, uint256 tokenId) public whenNotPaused {
        require(batches[batchId].redeemed[tokenId] == false, "Token already redeemed");
        batches[batchId].redeemed[tokenId] = true;
        emit TokenRedeemed(batchId, tokenId);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}