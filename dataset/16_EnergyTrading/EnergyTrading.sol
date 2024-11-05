// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EnergyTrading {
    struct EnergyTransaction {
        address buyer;
        address seller;
        uint256 energyQuantity;
        uint256 price;
        bool executed;
    }
    EnergyTransaction[] public transactions;

    // Place a buy order
    function placeBuyOrder(uint256 quantity, uint256 price) external {
        EnergyTransaction memory transaction = EnergyTransaction({
            buyer: msg.sender,
            seller: address(0),
            energyQuantity: quantity,
            price: price,
            executed: false
        });

        transactions.push(transaction);
    }

    // Place a sell order
    function placeSellOrder(uint256 quantity, uint256 price) external {
        EnergyTransaction memory transaction = EnergyTransaction({
            buyer: address(0),
            seller: msg.sender,
            energyQuantity: quantity,
            price: price,
            executed: false
        });

        transactions.push(transaction);
    }

    // Match buy and sell orders
    function matchOrders(uint256 transactionId) external {
        EnergyTransaction storage buyOrder = transactions[transactionId];

        require(buyOrder.buyer != address(0), "Invalid transaction ID");
        require(buyOrder.executed == false, "Transaction already executed");

        for (uint256 i = 0; i < transactions.length; i++) {
            EnergyTransaction storage sellOrder = transactions[i];

            if (
                sellOrder.seller != address(0) &&
                sellOrder.executed == false &&
                sellOrder.energyQuantity == buyOrder.energyQuantity &&
                sellOrder.price <= buyOrder.price
            ) {
                buyOrder.seller = sellOrder.seller;
                sellOrder.buyer = buyOrder.buyer;
                buyOrder.executed = true;
                sellOrder.executed = true;
                break;
            }
        }
    }

    // Execute a transaction and transfer funds
    function executeTransaction(uint256 transactionId) external {
        EnergyTransaction storage transaction = transactions[transactionId];

        require(
            transaction.buyer == msg.sender || transaction.seller == msg.sender,
            "Unauthorized"
        );
        require(transaction.executed == true, "Transaction not yet matched");

        uint256 totalAmount = transaction.energyQuantity * transaction.price;

        (bool success, ) = transaction.seller.call{value: totalAmount}("");
        require(success, "Transaction failed");
    }
}
