// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@layerzerolabs/solidity-examples/contracts/token/oft/IOFT.sol";
import "@layerzerolabs/solidity-examples/contracts/token/oft/OFTCore.sol";

abstract contract OFTVotes is OFTCore, ERC20Votes, IOFT {
    constructor(string memory _name, string memory _symbol, address _lzEndpoint) ERC20
}