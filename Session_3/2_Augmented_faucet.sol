// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract AugmentedFaucet {

    //internal variable, stores the 4 addresses allowed to withdraw
    address[] allowedUsers;
    address owner;
    uint max_users;
    // constructor function, only called once when contract is deployed
    constructor(uint _max_users) {
        // store in the variable owner the address of whoever deployed the contract
        owner = msg.sender;
        // store the number of max users that can withdraw from the faucet
        max_users = _max_users;
    }

    //Withdraw function
    //  Argument => amount to be withdrawn
    //This is a public function (i.e. accessible from outside the contract
    function withdraw(uint amount) public {
        require(amount <= 0.2 ether, "Max withdraw = 0.2 ether"); //max amount of withdraw is 0.2 ether
        require(address(this).balance >= amount, "Insufficient funds"); //max amount is available balance

        // store a boolean variable to see whether the withdraw was authorized
        bool paid = false;
        // loop over all allowed users to see if msg.sender is present
        for (uint i; i < allowedUsers.length; i++) {
            if (allowedUsers[i] == msg.sender) {
                // if msg.sender is allowed, pay him
                payable(msg.sender).transfer(amount);
                paid = true;
            }
        }
        // if msg.sender has not already been paid and max users is not reached, add him to allowed users, and pay him
        if (paid == false && allowedUsers.length < max_users){
            allowedUsers.push(msg.sender);
            payable(msg.sender).transfer(amount);
            paid = true;
        }
        // error message if withdraw could not be completed
        require(paid == true, "You are not able to withdraw, max_users has already been reached");
    }

    // the contract owner only can reset allowed users
    function resetAllowedUsers() public {
        require(msg.sender == owner, "Only the contract owner can invoke this function");
        delete allowedUsers;
    }

    // function to accept any incoming payments in ether
    receive() external payable {}
}