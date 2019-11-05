pragma solidity 0.5.0;

import "../SnakesAndLadders.sol";

contract SnakesAndLaddersMock is SnakesAndLadders {
    uint nonce = 0;

    function setNonce(uint n) public {
        nonce = n;
    }

    /**
     * Returns a NOT a random number
     */
    function random() public view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(nonce)));
    }
}
