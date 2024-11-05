pragma solidity >=0.4.22 <0.9.0;

contract StudentMarksManager {
    address public owner;
    mapping(address => bool) public teachers;
    string[] public courses;
    uint public studentCount;

    struct Student {
        bool exists;
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

    constructor() public {
        owner = msg.sender;
    }

function addTeacher(address _teacher) public onlyOwner {
    require(!teachers[_teacher], "Teacher already registered");

    teachers[_teacher] = true;

    emit TeacherAdded(_teacher);
}


function addCourse(string memory courseName) public onlyTeacher {
    require(bytes(courseName).length > 0, "Course name cannot be empty");

    for (uint i = 0; i < courses.length; i++) {
        string memory existingCourse = courses[i];
        if (keccak256(bytes(existingCourse)) == keccak256(bytes(courseName))) {
            revert("Course already exists");
        }
    }

    courses.push(courseName);
    emit CourseAdded(courseName);
}


function addStudent() public onlyTeacher {
    studentCount = studentCount + 1;
    uint newStudentId = studentCount;

    Student storage newStudent = students[newStudentId];
    newStudent.exists = true;

    emit StudentAdded(newStudentId);
}


function addMark(uint studentId, string memory course, uint mark) public onlyTeacher {
    // Check if the course exists
    bool courseExists = false;
    for (uint i = 0; i < courses.length; i++) {
        if (keccak256(abi.encodePacked(courses[i])) == keccak256(abi.encodePacked(course))) {
            courseExists = true;
            break;
        }
    }
    require(courseExists, "Course does not exist");

    // Check if the student exists
    Student storage student = students[studentId];
    require(student.exists, "Student does not exist");

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
    require(courseExists, "Course does not exist in student's record");

    // Return the list of marks
    return marks;
}


function getAllMarks(uint studentId) public view onlyTeacher returns (string[] memory courses, uint[][] memory marks) {
    // Check if the student exists
    Student storage student = students[studentId];
    if (student.exists == false) {
        revert("Student does not exist");
    }

    // Initialize arrays for courses and marks
    uint courseCount = courses.length;
    string[] memory courseNames = new string[](courseCount);
    uint[][] memory allMarks = new uint[][](courseCount);

    // Iterate through all courses
    for (uint i = 0; i < courseCount; i = i + 1) {
        string memory courseName = courses[i];
        courseNames[i] = courseName;

        // Retrieve the list of marks for the student in the current course
        uint[] storage studentMarks = student.marks[courseName];
        uint markCount = studentMarks.length;
        uint[] memory marksForCourse = new uint[](markCount);

        for (uint j = 0; j < markCount; j = j + 1) {
            marksForCourse[j] = studentMarks[j];
        }

        allMarks[i] = marksForCourse;
    }

    return (courseNames, allMarks);
}


}