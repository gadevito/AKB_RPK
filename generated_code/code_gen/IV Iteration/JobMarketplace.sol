pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract JobMarketplace {
    using SafeMath for uint;

    address public owner;
    uint public jobCount;

    enum Status { Open, InProgress, Completed, Canceled }

    struct Job {
        string title;
        string description;
        uint payment;
        address client;
        address freelancer;
        Status status;
    }

    mapping(uint => Job) public jobs;

    event JobPosted(uint jobId, address client, string title, string description, uint payment);
    event JobBid(uint jobId, address freelancer);
    event JobAccepted(uint jobId, address freelancer);
    event JobCompleted(uint jobId);
    event JobCanceled(uint jobId);

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
        require(jobId > 0 && jobId <= jobCount, "Invalid job ID");
        _;
    }

    modifier jobIsOpen(uint jobId) {
        require(jobs[jobId].status == Status.Open, "Job is not open");
        _;
    }

    modifier jobIsInProgress(uint jobId) {
        require(jobs[jobId].status == Status.InProgress, "Job is not in progress");
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
    newJob.status = Status.Open;

    emit JobPosted(newJobId, msg.sender, _title, _description, _payment);
}


function bidOnJob(uint jobId) public validJobId(jobId) jobIsOpen(jobId) {
    // Ensure the caller is not the client who posted the job
    address client = jobs[jobId].client;
    require(msg.sender != client, "Client cannot bid on their own job");

    // Update the job's freelancer to the caller's address
    Job storage job = jobs[jobId];
    job.freelancer = msg.sender;

    // Change the job status to InProgress
    job.status = Status.InProgress;

    // Emit the JobBid event
    emit JobBid(jobId, msg.sender);
}


function acceptBid(uint jobId, address freelancer) public validJobId(jobId) jobIsOpen(jobId) onlyClient(jobId) {
    // Ensure the caller is the client of the job
    require(msg.sender == jobs[jobId].client, "Only the client can accept a bid");

    // Ensure the job ID is valid
    require(jobId < jobCount, "Invalid job ID");

    // Ensure the job status is Open
    require(jobs[jobId].status == Status.Open, "Job is not open");

    // Update the job's status to InProgress
    jobs[jobId].status = Status.InProgress;

    // Set the freelancer for the job
    jobs[jobId].freelancer = freelancer;

    // Emit the JobAccepted event with the job ID and freelancer address
    emit JobAccepted(jobId, freelancer);
}


function markJobCompleted(uint jobId) public onlyFreelancer(jobId) validJobId(jobId) jobIsInProgress(jobId) {
    Job storage job = jobs[jobId];
    job.status = Status.Completed;
    emit JobCompleted(jobId);
}


function cancelJob(uint jobId) public validJobId(jobId) onlyFreelancer(jobId) jobIsOpen(jobId) {
    Job storage job = jobs[jobId];
    job.status = Status.Canceled;
    emit JobCanceled(jobId);
}


}