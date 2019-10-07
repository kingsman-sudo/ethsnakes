pragma solidity 0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "../SnakesAndLadders.sol";

contract SnakesAndLaddersMock is SnakesAndLadders {
    uint nonce = 0;

    function setNonce(uint n) public {
        nonce = n;
    }

    /**
     * Returns a NOT a random number
     */
    function random(uint turn) public view returns(int8) {
        return int8(uint256(keccak256(abi.encodePacked(turn, nonce)))%6) + 1;
    }
}