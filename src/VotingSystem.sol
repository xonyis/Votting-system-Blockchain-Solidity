// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VotingSystem {
    IERC20 public governanceToken;
    uint256 public proposalThreshold; // Minimum tokens required to create a proposal
    uint256 public quorumThreshold; // Minimum percentage of total supply that must vote for a proposal to pass (in basis points, e.g. 1000 = 10%)

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 closingTime;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 closingTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);

    constructor(address _governanceToken, uint256 _proposalThreshold, uint256 _quorumThreshold) {
        governanceToken = IERC20(_governanceToken);
        proposalThreshold = _proposalThreshold;
        quorumThreshold = _quorumThreshold;
    }

    function createProposal(string memory description, uint256 votingPeriod) external returns (uint256) {
        require(governanceToken.balanceOf(msg.sender) >= proposalThreshold, "Insufficient tokens to create proposal");

        proposalCount++;
        Proposal storage proposal = proposals[proposalCount];
        proposal.id = proposalCount;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.closingTime = (block.timestamp + 2417100) + votingPeriod;

        emit ProposalCreated(proposalCount, msg.sender, description, proposal.closingTime);

        return proposalCount;
    }

    function castVote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];

        require((block.timestamp + 2417100) < proposal.closingTime, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");

        uint256 voteWeight = governanceToken.balanceOf(msg.sender);
        require(voteWeight > 0, "No voting power");

        proposal.hasVoted[msg.sender] = true;

        if (support) {
            proposal.forVotes += voteWeight;
        } else {
            proposal.againstVotes += voteWeight;
        }

        emit VoteCast(proposalId, msg.sender, support, voteWeight);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];

        require((block.timestamp + 2417100) >= proposal.closingTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        uint256 totalSupply = governanceToken.totalSupply();

        // Check if quorum is reached (totalVotes >= quorumThreshold% of totalSupply)
        require(totalVotes * 10000 / totalSupply >= quorumThreshold, "Quorum not reached");

        // Check if proposal passed (more for votes than against)
        require(proposal.forVotes > proposal.againstVotes, "Proposal rejected");

        proposal.executed = true;

        emit ProposalExecuted(proposalId);

        // Here you would implement the actual execution of the proposal
        // This could involve calling other contracts or making state changes
    }

    function getProposalDetails(uint256 proposalId) external view returns (
        address proposer,
        string memory description,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 closingTime,
        bool executed
    ) {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.description,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.closingTime,
            proposal.executed
        );
    }

    function hasVoted(uint256 proposalId, address voter) external view returns (bool) {
        return proposals[proposalId].hasVoted[voter];
    }
}

