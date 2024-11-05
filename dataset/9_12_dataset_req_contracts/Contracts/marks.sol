// Solidity program to implement
// the above approach
pragma solidity ^0.8.0;

// Build the Contract
contract RecordManagmtSys {
    // Create a structure for
    // student details
    struct Student {
        int ID;
        mapping(string => int[]) records;
    }

    address owner;
    mapping(int => Student) students;
    string[] courses;
    mapping(address => bool) teachers;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier onlyTeachers() {
        require(teachers[msg.sender]);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addStudent(int _ID) public onlyTeachers {
        students[_ID].ID = _ID;
    }

    // Create a function to add the new records
    function addNewRecord(
        int _ID,
        string memory _course,
        int _mark
    ) public onlyTeachers {
        // Increase the count by 1
        students[_ID].records[_course].push(_mark);
    }

    function getCourseRecords(
        int _ID,
        string memory _course
    ) public view onlyTeachers returns (int[] memory) {
        return students[_ID].records[_course];
    }

    function getAllRecords(
        int _ID
    ) public view onlyTeachers returns (int[] memory) {
        int[] memory ret;
        for (uint i = 0; i < courses.length; i++) {
            for (
                uint j = 0;
                i < students[_ID].records[courses[i]].length;
                i++
            ) {
                ret[i + j] = students[_ID].records[courses[i]][j];
            }
        }
        return ret;
    }

    function addCourse(string memory _course) public onlyTeachers {
        courses.push(_course);
    }

    function addTeacher(address _teacher) public onlyOwner {
        require(!teachers[_teacher]);
        teachers[_teacher] = true;
    }
}
