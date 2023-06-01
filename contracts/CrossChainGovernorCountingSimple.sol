// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (governance/extensions/GovernorCountingSimple.sol)

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/governance/Governor.sol";

/**
 * @dev Extension of {Governor} for simple, 3 options, vote counting.
 *
 * _Available since v4.3._
 */
abstract contract CrossChainGovernorCountingSimple is Governor {
    // The lz-chain IDs that the DAO expects to receive data from during the
    // collection phase
    uint16[] public spokeChains;

    constructor(uint16[] memory _spokeChains) {
        spokeChains = _spokeChains;
    }

    // Will store the vote data received from other chains
    // Does not include a map of users to votes because that information stays on the spoke chains.
    struct SpokeProposalVote {
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool initialized;
    }

    /**
     * @dev Supported vote types. Matches Governor Bravo ordering.
     */
    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    // Maps a proposal ID to a map of a chain ID to summarized spoke voting data
    mapping(uint256 => mapping(uint16 => SpokeProposalVote)) public spokeVotes;
    mapping(uint256 => ProposalVote) private _proposalVotes;

    /**
     * @dev See {IGovernor-COUNTING_MODE}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE()
        public
        pure
        virtual
        override
        returns (string memory)
    {
        return "support=bravo&quorum=for,abstain";
    }

    /**
     * @dev See {IGovernor-hasVoted}.
     */
    function hasVoted(uint256 proposalId, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _proposalVotes[proposalId].hasVoted[account];
    }

    /**
     * @dev Accessor to the internal vote counts.
     */
    function proposalVotes(uint256 proposalId)
        public
        view
        virtual
        returns (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        )
    {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];
        return (
            proposalVote.againstVotes,
            proposalVote.forVotes,
            proposalVote.abstainVotes
        );
    }

    /**
     * @dev See {Governor-_quorumReached}.
     */
    function _quorumReached(uint256 proposalId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];
        uint256 abstainVotes = proposalVote.abstainVotes;
        uint256 forVotes = proposalVote.forVotes;

        for (uint16 i = 0; i < spokeChains.length; i++) {
            SpokeProposalVote storage v = spokeVotes[proposalId][
                spokeChains[i]
            ];
            abstainVotes += v.abstainVotes;
            forVotes += v.forVotes;
        }

        return quorum(proposalSnapshot(proposalId)) <= forVotes + abstainVotes;
    }

    /**
     * @dev See {Governor-_voteSucceeded}. In this module, the forVotes must be strictly over the againstVotes.
     */
    function _voteSucceeded(uint256 proposalId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];
        uint256 againstVotes = proposalVote.againstVotes;
        uint256 forVotes = proposalVote.forVotes;

        for (uint16 i = 0; i < spokeChains.length; i++) {
            SpokeProposalVote storage v = spokeVotes[proposalId][
                spokeChains[i]
            ];
            againstVotes += v.againstVotes;
            forVotes += v.forVotes;
        }
        return forVotes > againstVotes;
    }

    /**
     * @dev See {Governor-_countVote}. In this module, the support follows the `VoteType` enum (from Governor Bravo).
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory // params
    ) internal virtual override {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        require(
            !proposalVote.hasVoted[account],
            "GovernorVotingSimple: vote already cast"
        );
        proposalVote.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            proposalVote.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            proposalVote.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalVote.abstainVotes += weight;
        } else {
            revert("GovernorVotingSimple: invalid value for enum VoteType");
        }
    }
}
