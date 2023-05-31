// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";

contract CrossChainDAO is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes
{
    constructor(IVotes _token)
        Governor("CrossChainDAO")
        GovernorSettings(
            0, /* 0 block */
            30, /* 6 minutes */
            0
        )
        GovernorVotes(_token)
    {}

    function quorum(uint256 blockNumber)
        public
        pure
        override
        returns (uint256)
    {
        return 1e18;
    }

    // The following functions are overrides required by Solidity.

    function votingDelay()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }
}
