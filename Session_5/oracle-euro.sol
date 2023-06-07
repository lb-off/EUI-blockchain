// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "github.com/provable-things/ethereum-api/blob/master/contracts/solc-v0.8.x/provableAPI.sol";

contract EuroOracle is usingProvable { 
   // Store query ids
   bytes32 query_id;
   // Store ETH price;
   uint256 public ETH_EUR;
   string public ETH_EUR_str;

   // events
   event ValueUpdated(string price);  
   event ProvableQueryCalled(string description);

   // save the address of the owner of this contract
   address payable owner = payable(msg.sender);
  
   // callback for the query
    function __callback(bytes32 id, string memory result) public {            
       if (query_id == id){
           ETH_EUR_str = result;
        // parse result from string to number
           ETH_EUR = parseInt(ETH_EUR_str);
       }
       emit ValueUpdated(ETH_EUR_str);      
   }

   // call this function to access web services
   function updatePrice() public payable {
       if (provable_getPrice("URL") > address(this).balance) {
           emit ProvableQueryCalled("Need funds to make query");
       } else {  
           emit ProvableQueryCalled("Query sent, please wait");
           query_id = provable_query("URL", "json(https://api.pro.coinbase.com/products/ETH-EUR/ticker).price");
       }       
   }

   function refund() public {
       require(msg.sender == owner, 'Only the owner of this contract can call this function');   
       // refund back to the owner the funds in the contract
       owner.transfer(address(this).balance);
   }
  
   // accept any incomming transactinos
   receive() external payable {}
}