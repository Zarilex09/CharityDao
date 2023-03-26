pragma solidity ^0.8.0;

import "./CommunityDAO.sol";

contract CommunityProjectVoting {
    CommunityDAO public dao;
    uint256 public votingDuration;
    uint256 public minVotesRequired;
    uint256 public votingDeadline;
    uint256 public quorumPercentage;
    mapping (uint256 => mapping (address => bool)) public votes;

    event VoteCasted(address voter, uint256 projectId);
    event ProjectApproved(uint256 projectId);

    constructor(address _daoAddress, uint256 _votingDuration, uint256 _minVotesRequired, uint256 _quorumPercentage) {
        dao = CommunityDAO(_daoAddress);
        votingDuration = _votingDuration;
        minVotesRequired = _minVotesRequired;
        quorumPercentage = _quorumPercentage;
    }

    //allow users to vote if certain conditions are met
    function castVote(uint256 _projectId) public {
        require(dao.projects(_projectId).organizer != address(0), "Project does not exist");
        require(!votes[_projectId][msg.sender], "Vote already casted");
        require(block.timestamp <= votingDeadline, "Voting period has ended");

        votes[_projectId][msg.sender] = true;

        emit VoteCasted(msg.sender, _projectId);
    }

    //allow organizers to approve if certain conditions are met
    function approveProject(uint256 _projectId) public {
        require(dao.projects(_projectId).organizer != address(0), "Project does not exist");
        require(dao.projects(_projectId).isFunded, "Project is not fully funded");
        require(!dao.projects(_projectId).isVolunteerAssigned, "Volunteers already assigned");
        require(block.timestamp <= votingDeadline, "Voting period has ended");

        uint256 voteCount = 0;
        uint256 totalVotes = dao.projectCount();
        for (uint256 i = 1; i <= totalVotes; i++) {
            if (votes[_projectId][dao.projects(i).organizer]) {
                voteCount++;
            }
        }

        uint256 quorum = (totalVotes * quorumPercentage) / 100;
        require(voteCount >= minVotesRequired && voteCount >= quorum, "Not enough votes to approve project");

        dao.assignVolunteer(_projectId, msg.sender);

        emit ProjectApproved(_projectId);
    }

    //starts a new voting period with a deadline
    function startVotingPeriod() public {
        require(block.timestamp > votingDeadline, "Voting period has not ended");
        votingDeadline = block.timestamp + votingDuration;
    }

    //set the minimum required percentage
    function setQuorumPercentage(uint256 _quorumPercentage) public {
        quorumPercentage = _quorumPercentage;
    }

    //set the minimum required votes
    function setMinVotesRequired(uint256 _minVotesRequired) public {
        minVotesRequired = _minVotesRequired;
    }

    //set the voting duration
    function setVotingDuration(uint256 _votingDuration) public {
        votingDuration = _votingDuration;
    }
}