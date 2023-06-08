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
    receive() external payable {}
}
