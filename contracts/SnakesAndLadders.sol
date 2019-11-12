pragma solidity 0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract SnakesAndLadders is Ownable {
    using SafeMath for uint;
    using SafeMath for uint8;  // 0-255

    // All balances
    mapping(address => uint) public balances;
    uint totalBalance;

    // Payout addresses
    address payout1;
    address payout2;

    // Board composition
    uint8 constant tiles = 100;
    mapping(uint8 => uint8) private boardElements;

    // Player: is true if it's the user, otherwise is the AI
    // Turn: starting from 1
    // Move: the dice move from 1 to 6
    event LogGame(address sender, bool result, int balancediff, uint seed);
    event LogAddBalance(address sender, uint amount);
    event LogWithdrawBalance(address sender, uint amount);
    event LogAddFunds(address sender, uint amount);
    event LogPayout(address sender, uint amount);

    constructor(address _payout1, address _payout2) public {
        // ladders
        boardElements[4] = 14;
        boardElements[8] = 32;
        boardElements[20] = 38;
        boardElements[28] = 84;
        boardElements[40] = 59;
        boardElements[58] = 83;
        boardElements[72] = 93;
        // snakes
        boardElements[15] = 3;
        boardElements[31] = 9;
        boardElements[44] = 26;
        boardElements[62] = 19;
        boardElements[74] = 70;
        boardElements[85] = 33;
        boardElements[91] = 71;
        boardElements[98] = 80;
        // payouts
        payout1 = _payout1;
        payout2 = _payout2;
    }

    /**
     * Avoid sending money directly to the contract
     */
    function () external payable {
        revert("Use addBalance to send money.");
    }

    /**
     * Adds balance and plays a game
     */
    function playNow(uint amount) public payable {
        require(msg.value > 0, "You must send something when calling this function");
        emit LogAddBalance(msg.sender, msg.value);
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
        play(amount);
    }

    /**
     * Plays the game
     */
    function play(uint amount) public {
        require(amount > 0, "You must send something to bet");
        require(amount <= balances[msg.sender], "You don't have enough balance to play");
        require(amount*10 < address(this).balance, "You cannot bet more than 1/10 of this contract total balance");
        require(amount <= 1 ether, "Maximum bet amount is 1 ether");
        uint randomString = random();
        uint turn = 0;
        // let's decide who starts
        uint8 move = randomDice(randomString, turn);  // move 0 decides who starts
        bool player = false;  // true if next move is for player, false if for computer
        if (move == 1 || move == 2) {
            player = true;
        }
        // make all the moves and emit the results
        uint8 playerUser = 0;
        uint8 playerAI = 0;
        uint8 boardElement;
        while (playerUser != tiles && playerAI != tiles) {
            turn++;
            move = randomDice(randomString, turn);
            if (player) {
                playerUser = playerUser + move;
                boardElement = boardElements[playerUser];
                if (boardElement != 0) {
                    playerUser = boardElement;
                }
                if (playerUser > tiles) {
                    playerUser = tiles - (playerUser - tiles);
                }
            } else {
                playerAI = playerAI + move;
                boardElement = boardElements[playerAI];
                if (boardElement != 0) {
                    playerAI = boardElement;
                }
                if (playerAI > tiles) {
                    playerAI = tiles - (playerAI - tiles);
                }
            }
            player = !player;
        }
        if (playerUser == tiles) {
            balances[msg.sender] += amount;
            totalBalance += amount;
            emit LogGame(msg.sender, true, int(amount), randomString);
        } else {
            balances[msg.sender] -= amount;
            totalBalance -= amount;
            emit LogGame(msg.sender, false, -int(amount), randomString);
        }
    }

    /**
     * Returns a non-miner-secure random uint
     */
    function random() public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
    }

    /**
     * Returns a random number from 1 to 6 based from a uint and turn
     */
    function randomDice(uint randomString, uint turn) public pure returns(uint8) {
        return uint8(randomString/2**(turn%256))%6 + 1;
    }

    /**
     * User adds balance
     */
    function addBalance() public payable {
        require(msg.value > 0, "You must send something to add into balance");
        emit LogAddBalance(msg.sender, msg.value);
        balances[msg.sender] += msg.value;
        totalBalance += msg.value;
    }

    /**
     * Withdraw all balance
     */
    function withdrawBalance() public {
        uint toWithdraw = balances[msg.sender];
        require(toWithdraw > 0, "There is no balance to withdraw");
        require(toWithdraw <= address(this).balance, "There are not enough funds in the contract to withdraw");
        emit LogWithdrawBalance(msg.sender, toWithdraw);
        balances[msg.sender] = 0;
        totalBalance -= toWithdraw;
        msg.sender.transfer(toWithdraw);
    }

    /**
     * Only the owner can add funds to the contract
    */
    function addFunds() public payable onlyOwner {
        require(msg.value > 0, "You must send something when calling this function");
        emit LogAddFunds(msg.sender, msg.value);
    }

    /**
     * Only owner can emit payouts
     */
    function payout(uint amount) public onlyOwner {
        require(amount > 0, "The balance that you want to withdraw must be more than 0");
        require(amount%2 == 0, "Amount to withdraw must be pair");
        require(address(this).balance - totalBalance >= amount, "There is not enough balance to withdraw");
        emit LogPayout(msg.sender, amount);
        uint half = amount/2;
        balances[payout1] += half;
        balances[payout2] += half;
        totalBalance += amount;
    }
}
