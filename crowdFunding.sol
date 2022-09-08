// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract CrowdFunding {
    mapping(address => uint) public contributors;
    address public admin;
    uint public numberOfContributors;
    uint public minimumContribution;
    uint public deadline;
    uint public goal;
    uint public raisedAmount;
    struct Request {
        string description;
        address payable recepient;
        uint value;
        bool completed;
        uint numberOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => Request) public requests;
    uint public numberOfRequests;

    constructor(uint _goal, uint _deadline) {
        goal = _goal;
        deadline = block.timestamp + _deadline;
        minimumContribution = 100 wei;
        admin = msg.sender;
    }

    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recepient, uint _value);
    event MakePaymentEvent(address _recepient, uint _value);
    
    function contribute() public payable {
        require(block.timestamp < deadline, 'Deadline has passed');
        require(msg.value >= minimumContribution, 'Minimum contribution not met');

        if(contributors[msg.sender] == 0) {
            numberOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;
        emit ContributeEvent(msg.sender, msg.value);
    }

    receive() payable external {
        contribute();
    }

    function getBalance() view public returns (uint) {
        return address(this).balance;
    }

    function getRefund() public {
        require(block.timestamp > deadline && raisedAmount < goal);
        require(contributors[msg.sender] > 0);

        address payable recepient = payable(msg.sender);
        uint value = contributors[msg.sender];
        recepient.transfer(value);

        contributors[msg.sender] = 0;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'Only admin can call this function!');
        _;
    }

    function createRequest(string memory _description, address payable _recepient, uint _value) public onlyAdmin {
        Request storage request = requests[numberOfRequests];
        numberOfRequests++;
        request.description = _description;
        request.recepient = _recepient;
        request.value = _value;
        request.completed = false;
        request.numberOfVoters = 0;
        emit CreateRequestEvent(_description, _recepient, _value);
    } 

    function voteRequest(uint _requestNo) public {
        require(contributors[msg.sender] > 0, 'You must be a contributor to vote!');
        Request storage request = requests[_requestNo];

        require(request.voters[msg.sender] == false, 'You have already voted!');
        request.voters[msg.sender] = true;
        request.numberOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyAdmin {
        require(raisedAmount >= goal, 'You cannot make payment, goal has not reached');
        Request storage request = requests[_requestNo];
        require(request.completed == false, 'Request has been completed');
        require(request.numberOfVoters > numberOfContributors / 2); // 50% of contributors votted
        request.recepient.transfer(request.value);
        request.completed = true;
        emit MakePaymentEvent(request.recepient, request.value);
    }
}
