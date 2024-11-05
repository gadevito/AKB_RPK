pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StudentMarksManager {
    using SafeMath for uint;

    address public owner;
    mapping(address => bool) public teachers;
    string[] public courses;
    mapping(uint => Student) public students;
    uint public studentCount;

    struct Student {
        bool exists;
        mapping(string => uint[]) marks;
    }

    event TeacherAdded(address indexed teacher);
    event StudentAdded(uint indexed studentId);
    event CourseAdded(string course);
    event MarkAdded(uint indexed studentId, string course, uint mark);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier onlyTeacher() {
        require(teachers[msg.sender], "Only a registered teacher can call this function");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

function addTeacher(address _teacher) public onlyOwner {
    require(!teachers[_teacher], "Teacher already exists");
    teachers[_teacher] = true;
    emit TeacherAdded(_teacher);
}


function addCourse(string memory _course) public onlyTeacher {
    // Check if the course already exists
    for (uint i = 0; i < courses.length; i = i + 1) {
        string memory existingCourse = courses[i];
        if (keccak256(abi.encodePacked(existingCourse)) == keccak256(abi.encodePacked(_course))) {
            revert("Course already exists");
        }
    }

    // Add the course to the courses array
    courses.push(_course);

    // Emit the CourseAdded event
    emit CourseAdded(_course);
}


function addStudent() public onlyTeacher {
    studentCount = studentCount + 1;
    uint newStudentId = studentCount;

    Student storage newStudent = students[newStudentId];
    // Initialize the new student struct fields if necessary

    emit StudentAdded(newStudentId);
}


function addMark(uint studentId, string memory course, uint mark) public onlyTeacher {
    // Check if the student exists
    Student storage student = students[studentId];
    require(student.exists, "Student does not exist");

    // Check if the course exists
    bool courseExists = false;
    for (uint i = 0; i < courses.length; i++) {
        if (keccak256(abi.encodePacked(courses[i])) == keccak256(abi.encodePacked(course))) {
            courseExists = true;
            break;
        }
    }
    require(courseExists, "Course does not exist");

    // Add the mark to the student's record for the specified course
    student.marks[course].push(mark);

    // Emit the MarkAdded event
    emit MarkAdded(studentId, course, mark);
}


function getMarksByCourse(uint studentId, string memory course) public view onlyTeacher returns (uint[] memory) {
    // Check if the student exists
    Student storage student = students[studentId];
    bool studentExists = student.exists;
    require(studentExists, "Student does not exist");

    // Check if the course exists in the student's record
    uint[] storage marks = student.marks[course];
    bool courseExists = marks.length > 0;
    require(courseExists, "Course does not exist for the student");

    // Return the list of marks
    return marks;
}


function getAllMarks(uint studentId) public view onlyTeacher returns (string[] memory, uint[][] memory) {
    // Check if the student exists
    Student storage student = students[studentId];
    require(student.exists, "Student does not exist");

    // Initialize arrays for course names and marks
    uint courseCount = courses.length;
    string[] memory courseNames = new string[](courseCount);
    uint[][] memory allMarks = new uint[][](courseCount);

    // Iterate through all courses and retrieve marks for each course
    for (uint i = 0; i < courseCount; i = i + 1) {
        string memory course = courses[i];
        courseNames[i] = course;
        allMarks[i] = student.marks[course];
    }

    // Return the arrays containing course names and marks
    return (courseNames, allMarks);
}


}