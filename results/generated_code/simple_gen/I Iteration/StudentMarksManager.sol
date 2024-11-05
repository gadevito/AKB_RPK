pragma solidity >=0.4.22 <0.9.0;

contract StudentMarksManager {
    address public owner;
    mapping(address => bool) public teachers;
    mapping(uint => Student) public students;
    mapping(string => bool) public courses;
    string[] public courseList;

    struct Student {
        uint id;
        mapping(string => uint[]) marks;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyTeacher() {
        require(teachers[msg.sender], "Only teachers can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addTeacher(address _teacher) public onlyOwner {
        teachers[_teacher] = true;
    }

    function addCourse(string memory _course) public onlyTeacher {
        require(!courses[_course], "Course already exists");
        courses[_course] = true;
        courseList.push(_course);
    }

    function storeStudent(uint _id) public onlyTeacher {
        require(students[_id].id == 0, "Student already exists");
        students[_id].id = _id;
    }

    function addMark(uint _id, string memory _course, uint _mark) public onlyTeacher {
        require(courses[_course], "Course does not exist");
        require(students[_id].id != 0, "Student does not exist");
        students[_id].marks[_course].push(_mark);
    }

    function getMarksForCourse(uint _id, string memory _course) public view onlyTeacher returns (uint[] memory) {
        require(students[_id].id != 0, "Student does not exist");
        return students[_id].marks[_course];
    }

    function getAllMarks(uint _id) public view onlyTeacher returns (string[] memory, uint[][] memory) {
        require(students[_id].id != 0, "Student does not exist");

        uint courseCount = courseList.length;
        string[] memory courseNames = new string[](courseCount);
        uint[][] memory allMarks = new uint[][](courseCount);

        for (uint i = 0; i < courseCount; i++) {
            string memory course = courseList[i];
            courseNames[i] = course;
            allMarks[i] = students[_id].marks[course];
        }

        return (courseNames, allMarks);
    }
}