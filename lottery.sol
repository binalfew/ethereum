// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery {
    address payable[] public players;
    address public manager;

    constructor() {
        manager = msg.sender;
    }

    receive() external payable {
        require(msg.value == 0.1 ether);
        require(msg.sender != manager, 'Manager of the lottery cannot place a bid');
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint) {
       require(msg.sender == manager);
       return address(this).balance; 
    }

    function random() public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function pickWinner() public {
       require(msg.sender == manager);
       require(players.length >= 3);

       uint r = random();
       address payable winner;
       
       uint index = r % players.length;
       winner = players[index];

       winner.transfer(getBalance());
       players = new address payable[](0); // reset the lottery
    }
}

// Additional features
// Change the contract so that the manager of the lottery cannot participate in the lottery
// Change the contract so that the manager is automatically added to the lottery without sending any ether
// Chagne the contract so that anyone can pick the winner and finish the lottery if there are at least 10 players
// Change the contract so that the manager receives a fee of 10% of the lottery funds
