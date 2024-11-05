pragma solidity >=0.4.22 <0.9.0;

contract StudentMarksManager {
    address public owner;
    mapping(address => bool) public teachers;
    string[] public courses;
    uint public studentCount;

    struct Student {
        mapping(string => uint[]) marks;
    }

    mapping(uint => Student) internal students;

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

    for (uint i = 0; i < courses.length; i = i + 1) {
        string memory existingCourse = courses[i];
        require(keccak256(bytes(existingCourse)) != keccak256(bytes(courseName)), "Course already exists");
    }

    courses.push(courseName);
    emit CourseAdded(courseName);
}


function addStudent() public onlyTeacher {
    studentCount = studentCount + 1;
    uint newStudentId = studentCount;

    Student storage newStudent = students[newStudentId];
    // Initialize the new student struct fields if any

    emit StudentAdded(newStudentId);
}


function addMark(uint studentId, string memory course, uint mark) public onlyTeacher {
    // Check if the student exists
    require(studentId < studentCount, "Student does not exist");

    // Check if the course exists
    bool courseExists = false;
    for (uint i = 0; i < courses.length; i++) {
        if (keccak256(abi.encodePacked(courses[i])) == keccak256(abi.encodePacked(course))) {
            courseExists = true;
            break;
        }
    }
    require(courseExists, "Course does not exist");

    // Add the mark to the student's list of marks for the specified course
    Student storage student = students[studentId];
    student.marks[course].push(mark);

    // Emit the MarkAdded event
    emit MarkAdded(studentId, course, mark);
}


function getMarksByCourse(uint studentId, string memory course) public view onlyTeacher returns (uint[] memory) {
    // Check if the student exists
    require(studentId < studentCount, "Student does not exist");

    // Retrieve the student record
    Student storage student = students[studentId];

    // Check if the course exists in the student's record
    uint[] storage marks = student.marks[course];
    require(marks.length > 0, "Course does not exist for the student");

    // Return the list of marks
    return marks;
}


function getAllMarks(uint studentId) public view onlyTeacher returns (string[] memory, uint[][] memory) {
    // Check if the student exists
    require(studentId < studentCount, "Student does not exist");

    // Initialize arrays for course names and marks
    string[] memory courseNames = new string[](courses.length);
    uint[][] memory allMarks = new uint[][](courses.length);

    // Iterate through all courses and retrieve marks for each course
    for (uint i = 0; i < courses.length; i = i + 1) {
        string memory courseName = courses[i];
        courseNames[i] = courseName;

        // Retrieve marks for the course
        uint[] storage marks = students[studentId].marks[courseName];
        uint[] memory marksCopy = new uint[](marks.length);
        for (uint j = 0; j < marks.length; j = j + 1) {
            marksCopy[j] = marks[j];
        }
        allMarks[i] = marksCopy;
    }

    // Return the arrays containing course names and marks
    return (courseNames, allMarks);
}


}