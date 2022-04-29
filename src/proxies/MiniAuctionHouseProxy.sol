// SPDX-License-Identifier: GPL-3.0

/// @title The MINI Auction House Proxy 

pragma solidity ^0.8.6;

import { TransparentUpgradeableProxy } from 'openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

contract MiniAuctionHouseProxy is TransparentUpgradeableProxy {
    constructor(
        address logic,
        address admin,
        bytes memory data
    ) TransparentUpgradeableProxy(logic, admin, data) {}
}
