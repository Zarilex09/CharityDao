pragma solidity ^0.8.0;

contract CommunityDAO {
    struct CommunityProject {
        string name;
        string description;
        address organizer;
        bool isFunded;
        bool isVolunteerAssigned;
        address[] volunteers;
        uint256 fundsRaised;
        uint256 fundsNeeded;
    }

    mapping (uint256 => CommunityProject) public projects;
    uint256 public projectCount;

    event ProjectCreated(uint256 projectId, string name, string description, address organizer, uint256 fundsNeeded);
    event ProjectFunded(uint256 projectId, uint256 fundsRaised);
    event VolunteerAssigned(uint256 projectId, address volunteer);

    //Create a community project
    function createProject(string memory _name, string memory _description, uint256 _fundsNeeded) public {
        projectCount++;
        projects[projectCount] = CommunityProject(_name, _description, msg.sender, false, false, new address[](0), 0, _fundsNeeded);

        emit ProjectCreated(projectCount, _name, _description, msg.sender, _fundsNeeded);
    }

    //Fund Project by passing in Id and sending ether
    function fundProject(uint256 _projectId) public payable {
        require(msg.value > 0, "Must send funds to fund the project");
        require(!projects[_projectId].isFunded, "Project already funded");

        projects[_projectId].fundsRaised += msg.value;

        if (projects[_projectId].fundsRaised >= projects[_projectId].fundsNeeded) {
            projects[_projectId].isFunded = true;
        }

        emit ProjectFunded(_projectId, msg.value);
    }

    //Assign volunteers to projects, only organizer can assign
    function assignVolunteer(uint256 _projectId, address _volunteer) public {
        require(msg.sender == projects[_projectId].organizer, "Only the organizer can assign volunteers");
        require(!projects[_projectId].isVolunteerAssigned, "Volunteer already assigned");

        projects[_projectId].volunteers.push(_volunteer);
        projects[_projectId].isVolunteerAssigned = true;

        emit VolunteerAssigned(_projectId, _volunteer);
    }


    //allows users to retrieve all of the details for a specific project by passing in the project ID
    function getProject(uint256 _projectId) public view returns (string memory, string memory, address, bool, bool, address[] memory, uint256, uint256) {
        CommunityProject storage project = projects[_projectId];
        return (project.name, project.description, project.organizer, project.isFunded, project.isVolunteerAssigned, project.volunteers, project.fundsRaised, project.fundsNeeded);
    }

    //allows users to specify the exact amount they want to donate instead of sending it with the transaction
    function donateToProject(uint256 _projectId, uint256 _amount) public payable {
        require(msg.value == _amount, "Amount sent must match the amount specified");
        require(!projects[_projectId].isFunded, "Project already funded");

        projects[_projectId].fundsRaised += _amount;

        if (projects[_projectId].fundsRaised >= projects[_projectId].fundsNeeded) {
            projects[_projectId].isFunded = true;
        }

        emit ProjectFunded(_projectId, _amount);
    }

    //allows users to retrieve a list of all project IDs associated with a specific organizer
    function getProjectsByOrganizer(address _organizer) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](projectCount);
        uint256 counter = 0;
        for (uint256 i = 1; i <= projectCount; i++) {
            if (projects[i].organizer == _organizer) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    ////allows users to retrieve a list of all project IDs that a specific volunteer is assigned to
    function getProjectsByVolunteer(address _volunteer) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](projectCount);
        uint256 counter = 0;
        for (uint256 i = 1; i <= projectCount; i++) {
            for (uint256 j = 0; j < projects[i].volunteers.length; j++) {
                if (projects[i].volunteers[j] == _volunteer) {
                    result[counter] = i;
                    counter++;
                    break;
                }
            }
        }
        return result;
    }
}