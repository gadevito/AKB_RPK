// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract StudentMarksManager {
    address public owner;
    mapping(address => bool) public teachers;
    mapping(uint => Student) public students;
    mapping(uint => mapping(string => uint[])) public studentMarks;
    string[] public courses;

    struct Student {
        uint id;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyTeacher() {
        require(teachers[msg.sender], "Only teacher can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function addTeacher(address _teacher) public onlyOwner {
        teachers[_teacher] = true;
    }

    function addCourse(string memory _course) public onlyTeacher {
        courses.push(_course);
    }

    function storeStudent(uint _id) public onlyTeacher {
        require(students[_id].id == 0, "Student already exists");
        students[_id] = Student(_id);
    }

    function addMark(uint _id, string memory _course, uint _mark) public onlyTeacher {
        require(students[_id].id != 0, "Student does not exist");
        studentMarks[_id][_course].push(_mark);
    }

    function getMarksForCourse(uint _id, string memory _course) public view onlyTeacher returns (uint[] memory) {
        require(students[_id].id != 0, "Student does not exist");
        return studentMarks[_id][_course];
    }

    function getAllMarks(uint _id) public view onlyTeacher returns (string[] memory, uint[][] memory) {
        require(students[_id].id != 0, "Student does not exist");
        uint courseCount = courses.length;
        uint[][] memory allMarks = new uint[][](courseCount);
        for (uint i = 0; i < courseCount; i++) {
            allMarks[i] = studentMarks[_id][courses[i]];
        }
        return (courses, allMarks);
    }
}