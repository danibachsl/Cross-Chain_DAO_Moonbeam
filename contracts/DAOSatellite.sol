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
            (, uint256 proposalId, uint256 proposalStart) = abi.decode(_payload, (uint16, uint256, uint256));
            require(!isProposal(proposalId), "Proposal ID must be unique.");

            uint256 cutOffBlockEstimation = 0;
            if(proposalStart < block.timestamp) {
                uint256 blockAdjustment = (block.timestamp - proposalStart) / targetSecondsPerBlock;
                if(blockAdjustment < block.number) {
                    cutOffBlockEstimation = block.number - blockAdjustment;
                }
                else {
                    cutOffBlockEstimation = block.number;
                }
            }
            else {
                cutOffBlockEstimation = block.number;
            }

            proposals[proposalId] = RemoteProposal(cutOffBlockEstimation, false);
        } else if (option == 1) {
            // Send vote results back to the hub chain
            uint256 proposalId = abi.decode(_payload, (uint256));
            ProposalVote storage votes = proposalVotes[proposalId];
            bytes memory votingPayload = abi.encode(
                0, 
                abi.encode(proposalId, votes.forVotes, votes.againstVotes, votes.abstainVotes)
            );
            _lzSend({
                _dstChainId: hubChain,
                _payload: votingPayload,
                _refundAddress: payable(address(this)),
                _zroPaymentAddress: address(0x0),
                _adapterParams: bytes(""),
                // NOTE: DAOSatellite needs to be funded beforehand, in the constructor.
                //       There are better solutions, such as cross-chain swaps being built in from the hub chain, but
                //       this is the easiest solution for demonstration purposes.
                _nativeFee: 0.1 ether 
            });
            proposals[proposalId].voteFinished = true;
        }

        // Mechanism that allows users to vote. Very simmilar to GovernorCountingSimple contract
        function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256 balance)
        {
            RemoteProposal storage proposal = proposals[proposalId];
            require(
                !proposal.voteFinished,
                "DAOSatellite: vote not currently active"
            );
            require(
                isProposal(proposalId), 
                "DAOSatellite: not a started vote"
            );

            uint256 weight = token.getPastVotes(msg.sender, proposal.localVoteStart);
            _countVote(proposalId, msg.sender, support, weight);

            return weight;
        }

        function _countVote(uint256 proposalId, address account, uint8 support, uint256 weight) internal virtual 
        {
            ProposalVote storage proposalVote = proposalVotes[proposalId];

            require(!proposalVote.hasVoted[account], "DAOSatellite: vote already cast");
            proposalVote.hasVoted[account] = true;

            if (support == uint8(VoteType.Against)) {
                proposalVote.againstVotes += weight;
            } else if (support == uint8(VoteType.For)) {
                proposalVote.forVotes += weight;
            } else if (support == uint8(VoteType.Abstain)) {
                proposalVote.abstainVotes += weight;
            } else {
                revert("DAOSatellite: invalid value for enum VoteType");
            }
        }

    }
}
