//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0 <0.9.0;

contract CrowdFunding{
    mapping(address=>uint) public contributors; //mapping from the contributor's address to their contributed ether amount
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;

    struct Request{
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests;
    uint public numRequests;  //we have to create this variable to increment the no. of requests because in mapping we can't increment directly(like arrays)

    constructor( uint _target, uint _deadline){
        target = _target;
        deadline = block.timestamp + _deadline;
        manager = msg.sender;
        minimumContribution = 100 wei;
    }

    function sendEth() public payable{
        require(msg.value >= minimumContribution, "Minimum contribution is not met");
        require(block.timestamp < deadline, "Deadline has passed");

        if(contributors[msg.sender]==0){   //if the particular contributor has not made any contributions yet(i.e it's his first contribution) then increment the no. of contributors because this is a fresh contributor
            noOfContributors++;
        }
        contributors[msg.sender] += msg.value; //this is for adding the contribution, so if the same sender wants to contribute again then we only need to add the contribution and not increment the contributors
        raisedAmount += msg.value;

    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public{
        require(block.timestamp > deadline && raisedAmount < target, "You are not eligible for refund");
        require(contributors[msg.sender] > 0, "You have not contributed yet so no refund"); //we have to check if the contributor who is asking for refund has contributed or not
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;

    }

    modifier onlyManager{
        require(msg.sender == manager, "Only manager can call this function");
        _;
    }

    function createRequests(string memory _description, address payable _recipient, uint _value) public onlyManager{
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender] > 0, "You can't vote because you aren't a contributor");
        require(_requestNo <= numRequests, "Invalid request no.");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender] == false, "You have already voted once!");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;

    }

    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmount >= target, "Target is not achieved");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false, "This request is already completed");
        require(thisRequest.noOfVoters > (noOfContributors/2), "Majority does not support");
        thisRequest.recipient.transfer(thisRequest.value);
    }

}