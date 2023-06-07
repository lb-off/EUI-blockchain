// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

// declaration of the contract
contract Simple_Faucet {
    //Withdraw function
    //  Argument => amount to be withdrawn
    //This is a public function (i.e. accessible from outside the contract
    function withdraw(uint amount) public {
        require(amount <= 0.2 ether, "Max withdraw = 0.2 ether"); //max amount of withdraw is 0.2 ether
        require(address(this).balance >= amount, "Insufficient funds"); //max amount is available balance
        payable(msg.sender).transfer(amount); //pay the msg.sender (i.e. whoever triggered this execution) the amount
    }
    // function to accept any incoming payments in ether
    // this function slightly changes from what was recorded in the video because if this function is called something
    // else than receive() the interaction would be somewhat more complex. With this function, we can just send an
    // amount directly to the contract address in Metamask.
    receive() external payable {}
}