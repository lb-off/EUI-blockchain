// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import the default ERC20 implementation by openzeppelin
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
The contract extends the ERC20 contract to be mintable by anyone but up to a certain limit
defined by the contract owner.
*/
contract MaxMintToken is ERC20 {
    /*
    This section defines the internal variable of the smart contract. Recall that because
    the smart contract is ERC20, it also inherits all the variables (and functions) of ERC20.sol.
    */
    mapping(address => uint256) private minted;
    uint256 public total_minted;
    uint256 public max_mint;
    uint256 private max_mint_per_user;

    constructor(uint256 _max_mint, uint256 _max_mint_per_user) ERC20("EUI_coin", "EUC") {
        /*stores some parameters. 
        max_mint is the max total amount to be minted.
        max_mint_per_user si the total amount a user can mint.
        */
        max_mint = _max_mint;
        max_mint_per_user = _max_mint_per_user;
    }

    function mint(uint256 _amount) external {
        //define 2 variables to be used in this function
        uint256 amount = _amount;
        address account = msg.sender;
        // make a number of checks to make sure, we do not over-mint.
        require(total_minted < max_mint, "Total supply has already been minted");
        require(total_minted + amount <= max_mint, "Minting this much would exceed the max supply");
        require(minted[account] < max_mint_per_user, "User has already minted max");
        require(minted[account] + amount <= max_mint_per_user, "User cannot mint this much");
        //actually mint only if all checks pass. The _mint function is defined in ERC20.
        _mint(account, amount);
        //stored the value minted by this user and the total value minted.
        minted[account] += amount;
        total_minted += amount;
    }
}
