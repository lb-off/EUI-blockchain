// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import the ERC20 Interface
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Main contract: Governance Contract
contract Governance {

    // structure to store different voting options
    struct Option {
        uint id;
        string name;
        uint256 vote_count;
    }

    // stucture to store voters and check voting rights
    struct Voter {
        address addr;
        uint256 voted;
    }

    // address of the owner of this contract
    address owner;

    // variables storing info about the vote
    // check whether votes are open
    bool public is_live;
    // timestamp of when the votes will close
    uint256 public unLocktime;   
    // result of the vote
    Option public result; 

    // address of the governance token
    address public gov_token;

    // options submitted to the vote
    Option[] public options;

    // voters : account for voting rights
    Voter[] public voters;

    // called once at contract deployment time
    constructor(address _gov_token){
        owner = msg.sender;
        gov_token = _gov_token;
        is_live = false;
        unLocktime = 0;
    }

    // main function to cast a vote
    // ============================
    // it takes as argument, the vote_id of the option and
    // the quantity of governance token to associate with this vote
    function vote(uint vote_id, uint256 amount) public {
        require(is_live == true, "Vote is not live right now");
        require(block.timestamp < unLocktime, "Voting is now closed");

        require(vote_id < options.length, "Invalid vote_id");

        bool has_voted = isVoter(msg.sender);

        if (has_voted == false) {
            voters.push(Voter(msg.sender, 0));
        }

        uint voter_id = getVoterId(msg.sender);
        uint256 already_voted = getAlreadyVoted(voter_id);
        uint256 gov_token_balance = IERC20(gov_token).balanceOf(msg.sender);

        require(gov_token_balance > already_voted, "This account has already used all voting rights");
        
        require(amount < gov_token_balance - already_voted, "Insufficient voting rights");
            
        options[vote_id].vote_count += amount;
        voters[voter_id].voted += amount;
    }

    // view only functions
    // ===================
    // get the current winning option
    function get_current_winer() public view returns(uint id, string memory name, uint vote_count) {
        uint winner = 0;
        uint256 max_vote = 0;
        for (uint i=0; i < options.length; i++) {
            if (options[i].vote_count > max_vote) {
                winner = i;
                max_vote = options[i].vote_count;
            }
        }
        return (options[winner].id, options[winner].name, options[winner].vote_count);
    }

    // internal functions
    // ==================
    // check if addr is already a voter
    function isVoter(address addr) internal view returns(bool voter) {
        bool has_voted = false;
        for (uint i=0; i<voters.length; i++) {
            if (voters[i].addr == addr) {
                has_voted = true;
                break;
            }
        }
        return has_voted; 
    }

    // return the amount of votes already cast by voter_id
    function getAlreadyVoted(uint voter_id) internal view returns(uint256 voted) {
        return voters[voter_id].voted;
    }

    // get voter_id from address
    function getVoterId(address addr) internal view returns(uint id) {
        uint _id;
        for (uint i=0; i<voters.length; i++) {
            if (voters[i].addr == addr) {
                _id = i;
                break;
            }
        }
        return _id; 
    }

    // only owner functions
    // ====================
    // initiate de vote : takes locktime as argument
    function init_vote(uint256 _unLocktimeInSeconds) public {
        require(msg.sender == owner, "Only owner can add a new option");
        require(is_live == false, "There is an ongoing vote, it must ends before init");
        delete result;
        is_live = true;
        unLocktime = block.timestamp + _unLocktimeInSeconds;
    }

    // add an option to the vote
    function add_option(string memory name) public {
        require(msg.sender == owner, "Only owner can add a new option");
        require(is_live == false, "There is an ongoing vote, it must ends before adding an option");
        options.push(Option(options.length, name, 0));
    }

    // declare the winner of the vote
    function declareWinner() public {
        require(msg.sender == owner, "Only owner can reset options");
        require(is_live == true, "There is an ongoing vote, it must ends before reseting options");
        require(block.timestamp > unLocktime, "Voting is still open, winner cannot be declared");
        uint id;
        string memory name;
        uint256 votes;
        (id, name, votes) = get_current_winer();
        result = Option(id, name, votes);
        is_live = false;
    }

    // reset the previous vote and get ready for the next vote
    function reset_vote() public {
        require(msg.sender == owner, "Only owner can reset options");
        require(is_live == false, "There is an ongoing vote, it must ends before reseting options");
        delete options;
        delete voters;
        unLocktime = 0;
        is_live = false;
    }
}
