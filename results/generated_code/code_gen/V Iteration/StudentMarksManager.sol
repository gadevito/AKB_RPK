pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StudentMarksManager {
    using SafeMath for uint;

    address public owner;
    mapping(address => bool) public teachers;
    string[] public courses;
    uint public studentCount;

    struct Student {
        uint id;
        mapping(string => uint[]) marks;
    }

    mapping(uint => Student) public students;

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

    constructor() {
        owner = msg.sender;
    }

function addTeacher(address _teacher) public onlyOwner {
    require(!teachers[_teacher], "Teacher already registered");

    teachers[_teacher] = true;

    emit TeacherAdded(_teacher);
}


function addCourse(string memory _course) public onlyTeacher {
    // Check if the course already exists
    for (uint i = 0; i < courses.length; i++) {
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


function addStudent() public onlyTeacher returns (uint) {
    // Increment the student count to generate a new unique student ID
    studentCount = studentCount + 1;
    uint newStudentId = studentCount;

    // Initialize a new Student struct and store it in the students mapping
    Student storage newStudent = students[newStudentId];
    newStudent.id = newStudentId;
    // Initialize other fields of the Student struct as needed

    // Emit the StudentAdded event with the new student ID
    emit StudentAdded(newStudentId);

    return newStudentId;
}


function addMark(uint studentId, string memory course, uint mark) public onlyTeacher {
    // Check if the student exists
    Student storage student = students[studentId];
    require(student.id != 0, "Student does not exist");

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
    if (student.id == 0) {
        revert("Student does not exist");
    }

    // Check if the course exists in the student's record
    uint[] storage marks = student.marks[course];
    if (marks.length == 0) {
        revert("Course not found for the student");
    }

    // Return the list of marks
    return marks;
}


function getAllMarks(uint studentId) public view onlyTeacher returns (string[] memory, uint[][] memory) {
    // Check if the student exists
    if (students[studentId].id == 0) {
        revert("Student does not exist");
    }

    // Initialize arrays for course names and marks
    string[] memory courseNames = new string[](courses.length);
    uint[][] memory allMarks = new uint[][](courses.length);

    // Iterate through all courses
    for (uint i = 0; i < courses.length; i = i + 1) {
        // Retrieve the course name
        string memory courseName = courses[i];
        courseNames[i] = courseName;

        // Retrieve the marks for the given student in the current course
        uint[] memory marks = students[studentId].marks[courseName];
        allMarks[i] = marks;
    }

    // Return the arrays containing the course names and the marks
    return (courseNames, allMarks);
}


}