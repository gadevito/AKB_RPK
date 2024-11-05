pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract JobMarketplace {
    using SafeMath for uint;

    address public owner;
    uint public jobCount;

    enum JobStatus { Open, InProgress, Completed, Canceled }

    struct Job {
        string title;
        string description;
        uint payment;
        address client;
        address freelancer;
        JobStatus status;
    }

    mapping(uint => Job) public jobs;

    event JobPosted(uint jobId, address client, string title, string description, uint payment);
    event JobBid(uint jobId, address freelancer);
    event JobAccepted(uint jobId, address freelancer);
    event JobCompleted(uint jobId, address freelancer);
    event JobCanceled(uint jobId, address freelancer);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyClient(uint jobId) {
        require(msg.sender == jobs[jobId].client, "Only the client can call this function");
        _;
    }

    modifier onlyFreelancer(uint jobId) {
        require(msg.sender == jobs[jobId].freelancer, "Only the freelancer can call this function");
        _;
    }

    modifier validJobId(uint jobId) {
        require(jobId > 0 && jobId <= jobCount, "Invalid jobId");
        _;
    }

    modifier jobIsOpen(uint jobId) {
        require(jobs[jobId].status == JobStatus.Open, "Job is not open");
        _;
    }

    constructor() public {
        owner = msg.sender;
        jobCount = 0;
    }

function postJob(string memory _title, string memory _description, uint _payment) public {
    require(bytes(_title).length > 0, "Job title cannot be empty");
    require(bytes(_description).length > 0, "Job description cannot be empty");
    require(_payment > 0, "Payment must be greater than 0");

    jobCount = jobCount + 1;
    uint newJobId = jobCount;

    Job storage newJob = jobs[newJobId];
    newJob.title = _title;
    newJob.description = _description;
    newJob.payment = _payment;
    newJob.client = msg.sender;
    newJob.status = JobStatus.Open;

    emit JobPosted(newJobId, msg.sender, _title, _description, _payment);
}


function bidOnJob(uint jobId) public validJobId(jobId) jobIsOpen(jobId) {
    // Ensure the caller is not the client who posted the job
    address client = jobs[jobId].client;
    require(msg.sender != client, "Client cannot bid on their own job");

    // Update the job's freelancer field with the caller's address
    address freelancer = msg.sender;
    jobs[jobId].freelancer = freelancer;

    // Emit the JobBid event with the jobId and the caller's address
    emit JobBid(jobId, freelancer);
}


function acceptBid(uint jobId, address freelancer) public validJobId(jobId) jobIsOpen(jobId) onlyClient(jobId) {
    // Ensure the caller is the client who posted the job
    require(msg.sender == jobs[jobId].client, "Only the client can accept a bid");

    // Ensure the jobId is valid
    require(jobId < jobCount, "Invalid jobId");

    // Ensure the job status is Open
    Job storage job = jobs[jobId];
    require(job.status == JobStatus.Open, "Job is not open");

    // Update the job's status to InProgress
    job.status = JobStatus.InProgress;

    // Set the freelancer address for the job
    job.freelancer = freelancer;

    // Emit the JobAccepted event with the jobId and freelancer address
    emit JobAccepted(jobId, freelancer);
}


function markJobCompleted(uint jobId) public validJobId(jobId) onlyFreelancer(jobId) {
    Job storage job = jobs[jobId];
    require(job.status == JobStatus.InProgress, "Job is not in progress");

    job.status = JobStatus.Completed;

    emit JobCompleted(jobId, job.freelancer);
}


function cancelJob(uint jobId) public validJobId(jobId) onlyFreelancer(jobId) jobIsOpen(jobId) {
    Job storage job = jobs[jobId];
    job.status = JobStatus.Canceled;
    emit JobCanceled(jobId, msg.sender);
}


}