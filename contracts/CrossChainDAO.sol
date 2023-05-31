// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";

abstract contract CrossChainDAO is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    NonblockingLzApp
{
    constructor(IVotes _token, address lzEndpoint)
        Governor("CrossChainDAO")
        GovernorSettings(
            0, /* 0 block */
            30, /* 6 minutes */
            0
        )
        GovernorVotes(_token)
        NonblockingLzApp(lzEndpoint)
    {}

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory,
        uint64,
        bytes memory _payload
    ) internal override {
        // TODO: add cross-chain logic
    }

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
