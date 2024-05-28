// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
The contract extends the ERC20 contract to be mintable by anyone but up to a certain limit
defined by the contract owner.
*/
contract LiquidityToken is ERC20 {
    address private owner;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        owner = msg.sender;
    }

    function mint(uint256 _amount, address _beneficiary) external {
        require(owner == msg.sender, "Unauthorized mint of LT Token");
        _mint(_beneficiary, _amount);
    }

    function burn(uint256 _amount, address _beneficiary) external {
        require(owner == msg.sender, "Unauthorized burn of LT Token");
        _burn(_beneficiary, _amount);
    }
}
