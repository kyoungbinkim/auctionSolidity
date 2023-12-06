// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract ERC20Contract is ERC20 {

    constructor (string memory name, string memory symbol, address owner) ERC20(name, symbol) {
        _update(address(0), _msgSender(), 1000000000);
        _update(address(0), owner, 1000000000);
    }
    
}