//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
contract Auctoin{
    address payable public auctioneer;
    uint public stblock;//start time
    uint public etblock;//endblock
    enum Auc_State{started, Running, Endded, Cencelled}
    Auc_State public auctionState;
    uint public highestBid;
    uint public highestPayableBid;
    uint public bidInc;
    address payable public highestBidder;
    mapping(address=>uint) public bids;
    constructor(){
        auctioneer = payable(msg.sender);
        auctionState = Auc_State.Running;
        stblock = block.number;
        etblock = stblock + 240;
        bidInc = 1 ether;
    }
    modifier notOwner(){
        require(msg.sender != auctioneer,"owner cannot bid");
        _;
    }
    modifier Owner(){
        require(msg.sender == auctioneer,"owner cannot bid");
        _;
    }
    modifier started(){
        require(block.number>stblock);
        _;
    }
    modifier beforeEnding(){
        require(block.number<stblock);
        _;
    }
    function cancelAuc() public Owner{
        auctionState = Auc_State.Cencelled;
    }
    function min(uint a, uint b) pure private returns(uint){
        if(a<=b)
        return a;
        else
        return b;
    }
    function bid() public payable notOwner started beforeEnding{
     require(auctionState == Auc_State.Running);
     require(msg.value >=1 ether,"minimum 1 ether bid");
     uint currentBid = bids[msg.sender] + msg.value;
     require(currentBid>highestPayableBid);
     bids[msg.sender] = currentBid;
     if(currentBid < bids[highestBidder]){
         highestPayableBid = min(currentBid + bidInc, bids[highestBidder]);
     }
     else{
         highestPayableBid = min(currentBid, bids[highestBidder]+bidInc);
         highestBidder = payable(msg.sender);
    }
    }
    function finalize() public {
     require(auctionState == Auc_State.Cencelled || block.number>etblock);
     require(msg.sender == auctioneer || bids[msg.sender]>0);
     address payable person;
     uint value ;
     if(auctionState == Auc_State.Cencelled){
         person = payable(msg.sender);
         value = bids[msg.sender];
     }
     else{
         if(msg.sender == auctioneer){
             person = auctioneer;
             value = highestPayableBid; 
         }
         else{
             if(msg.sender == highestBidder){
                 person = highestBidder;
                 value = bids[highestBidder] - highestPayableBid;
             }
             else{
                 person = payable(msg.sender);
                 value = bids[msg.sender];
                }
            }
        }
        bids[msg.sender]=0;
        person.transfer(value);
    }
}