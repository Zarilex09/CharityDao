pragma solidity ^0.8.0;

import "./CommunityDAO.sol";

contract CommunityProjectVoting {
    CommunityDAO public dao;
    uint256 public votingDuration;
    uint256 public minVotesRequired;
    mapping (uint256 => mapping (address => bool)) public votes;

    event VoteCasted(address voter, uint256 projectId);
    event ProjectApproved(uint256 projectId);

    constructor(address _daoAddress, uint256 _votingDuration, uint256 _minVotesRequired) {
        dao = CommunityDAO(_daoAddress);
        votingDuration = _votingDuration;
        minVotesRequired = _minVotesRequired;
    }

    //users can cast their votes by passing in Id
    function castVote(uint256 _projectId) public {
        require(dao.projects(_projectId).organizer != address(0), "Project does not exist");
        require(!votes[_projectId][msg.sender], "Vote already casted");

        votes[_projectId][msg.sender] = true;

        emit VoteCasted(msg.sender, _projectId);
    }

    //approve projects once fully funded to assign volunteers
    function approveProject(uint256 _projectId) public {
        require(dao.projects(_projectId).organizer != address(0), "Project does not exist");
        require(dao.projects(_projectId).isFunded, "Project is not fully funded");
        require(!dao.projects(_projectId).isVolunteerAssigned, "Volunteers already assigned");

        uint256 voteCount = 0;
        uint256 totalVotes = dao.projectCount();
        for (uint256 i = 1; i <= totalVotes; i++) {
            if (votes[_projectId][dao.projects(i).organizer]) {
                voteCount++;
            }
        }

        require(voteCount >= minVotesRequired, "Not enough votes to approve project");

        dao.assignVolunteer(_projectId, msg.sender);

        emit ProjectApproved(_projectId);
    }

    function getVotesForProject(uint256 _projectId) public view returns (uint256) {
        uint256 voteCount = 0;
        uint256 totalVotes = dao.projectCount();
        for (uint256 i = 1; i <= totalVotes; i++) {
            if (votes[_projectId][dao.projects(i).organizer]) {
                voteCount++;
            }
        }
        return voteCount;
    }

}