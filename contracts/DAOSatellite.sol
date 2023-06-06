// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";
import "@openzeppelin/contracts/utils/Timers.sol";
import "@openzeppelin/contracts/utils/Checkpoints.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";

contract DAOSatellite is NonblockingLzApp {
    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct RemoteProposal {
        // Blocks provided by the hub chain as to when the local votes should start/finish.
        uint256 localVoteStart;
        bool voteFinished;
    }

    constructor(
        uint16 _hubChain,
        address _endpoint,
        IVotes _token,
        uint _targetSecondsPerBlock
    ) payable NonblockingLzApp(_endpoint) {
        hubChain = _hubChain;
        token = _token;
        targetSecondsPerBlock = _targetSecondsPerBlock;
    }

    uint16 public immutable hubChain;
    IVotes public immutable token;
    uint256 public immutable targetSecondsPerBlock;
    mapping(uint256 => RemoteProposal) public proposals;
    mapping(uint256 => ProposalVote) public proposalVotes;

    function isProposal(uint256 proposalId) public view returns (bool) {
        return proposals[proposalId].localVoteStart != 0;
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        require(
            _srcChainId == hubChain,
            "Only messages from the hub chain can be received!"
        );

        uint16 option;
        assembly {
            option := mload(add(_payload, 32))
        }

        if (option == 0) {
            // Begin a proposal on the local chain, with local block times
        } else if (option == 1) {
            // Send vote results back to the hub chain
        }
    }
}
