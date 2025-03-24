// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GovernanceToken.sol";
import "../src/VotingSystem.sol";

contract VotingSystemTest is Test {
    GovernanceToken public token;
    VotingSystem public votingSystem;

    address public admin = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public user3 = address(4);

    uint256 public constant INITIAL_SUPPLY = 1000000 * 10**18; // 1 million tokens
    uint256 public constant PROPOSAL_THRESHOLD = 100000 * 10**18; // 100k tokens to create proposal
    uint256 public constant QUORUM_THRESHOLD = 2000; // 20% quorum

    function setUp() public {
        vm.startPrank(admin);

        // Deploy token
        token = new GovernanceToken("Governance Token", "GOV", INITIAL_SUPPLY, admin);

        // Deploy voting system
        votingSystem = new VotingSystem(address(token), PROPOSAL_THRESHOLD, QUORUM_THRESHOLD);

        // Distribute tokens
        token.transfer(user1, 200000 * 10**18); // 200k tokens
        token.transfer(user2, 150000 * 10**18); // 150k tokens
        token.transfer(user3, 50000 * 10**18);  // 50k tokens

        vm.stopPrank();
    }

    function testCreateProposal() public {
        vm.startPrank(user1);

        // User1 creates a proposal
        uint256 proposalId = votingSystem.createProposal("Test Proposal", 1 days);

        // Check proposal was created
        (address proposer, string memory description, , , uint256 closingTime, bool executed) = votingSystem.getProposalDetails(proposalId);

        assertEq(proposer, user1);
        assertEq(description, "Test Proposal");
        assertEq(closingTime, block.timestamp + 1 days);
        assertEq(executed, false);

        vm.stopPrank();
    }

    function testFailCreateProposalInsufficientTokens() public {
        vm.startPrank(user3); // User3 only has 50k tokens, below threshold

        // Should fail
        votingSystem.createProposal("Test Proposal", 1 days);

        vm.stopPrank();
    }

    function testVoting() public {
        // User1 creates a proposal
        vm.prank(user1);
        uint256 proposalId = votingSystem.createProposal("Test Proposal", 1 days);

        // User2 votes for the proposal
        vm.prank(user2);
        votingSystem.castVote(proposalId, true);

        // User3 votes against the proposal
        vm.prank(user3);
        votingSystem.castVote(proposalId, false);

        // Check votes
        (, , uint256 forVotes, uint256 againstVotes, , ) = votingSystem.getProposalDetails(proposalId);

        assertEq(forVotes, 150000 * 10**18); // User2's balance
        assertEq(againstVotes, 50000 * 10**18); // User3's balance
    }

    function testFailDoubleVoting() public {
        // User1 creates a proposal
        vm.prank(user1);
        uint256 proposalId = votingSystem.createProposal("Test Proposal", 1 days);

        // User2 votes for the proposal
        vm.startPrank(user2);
        votingSystem.castVote(proposalId, true);

        // User2 tries to vote again (should fail)
        votingSystem.castVote(proposalId, false);

        vm.stopPrank();
    }

    function testExecuteProposal() public {
        // User1 creates a proposal
        vm.prank(user1);
        uint256 proposalId = votingSystem.createProposal("Test Proposal", 1 days);

        // User1 and User2 vote for the proposal (350k tokens total)
        vm.prank(user1);
        votingSystem.castVote(proposalId, true);

        vm.prank(user2);
        votingSystem.castVote(proposalId, true);

        // Fast forward past the closing time
        vm.warp(block.timestamp + 1 days + 1);

        // Execute the proposal
        vm.prank(admin);
        votingSystem.executeProposal(proposalId);

        // Check proposal was executed
        (, , , , , bool executed) = votingSystem.getProposalDetails(proposalId);
        assertEq(executed, true);
    }

    function testFailExecuteProposalQuorumNotReached() public {
        // User1 creates a proposal
        vm.prank(user1);
        uint256 proposalId = votingSystem.createProposal("Test Proposal", 1 days);

        // Only User3 votes (50k tokens, less than 20% quorum)
        vm.prank(user3);
        votingSystem.castVote(proposalId, true);

        // Fast forward past the closing time
        vm.warp(block.timestamp + 1 days + 1);

        // Should fail due to quorum not reached
        vm.prank(admin);
        votingSystem.executeProposal(proposalId);
    }
}

