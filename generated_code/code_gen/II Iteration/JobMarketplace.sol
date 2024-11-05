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
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyClient(uint jobId) {
        require(msg.sender == jobs[jobId].client, "Only client can call this function");
        _;
    }

    modifier onlyFreelancer(uint jobId) {
        require(msg.sender == jobs[jobId].freelancer, "Only freelancer can call this function");
        _;
    }

    modifier validJobId(uint jobId) {
        require(jobId > 0 && jobId <= jobCount, "Invalid job ID");
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


function bidOnJob(uint jobId) public {
    require(jobId > 0 && jobId <= jobCount, "Invalid job ID");

    Job storage job = jobs[jobId];
    address jobClient = job.client;
    Status jobStatus = job.status;

    require(jobClient != msg.sender, "Client cannot bid on their own job");
    require(jobStatus == Status.Open, "Job is not open for bidding");

    job.freelancer = msg.sender;
    job.status = Status.InProgress;

    emit JobBid(jobId, msg.sender);
}


function acceptBid(uint jobId, address freelancer) public validJobId(jobId) onlyClient(jobId) {
    // Ensure the job status is Open
    require(jobs[jobId].status == Status.Open, "Job is not open for accepting bids");

    // Update the job's status to InProgress
    jobs[jobId].status = Status.InProgress;

    // Set the freelancer's address for the job
    jobs[jobId].freelancer = freelancer;

    // Emit the JobAccepted event with the job ID and freelancer's address
    emit JobAccepted(jobId, freelancer);
}


function markJobCompleted(uint jobId) public validJobId(jobId) onlyFreelancer(jobId) {
    Job storage job = jobs[jobId];

    require(job.status == Status.InProgress, "Job is not in progress");

    job.status = Status.Completed;

    emit JobCompleted(jobId);
}


function cancelJob(uint jobId) public validJobId(jobId) onlyFreelancer(jobId) {
    Job storage job = jobs[jobId];
    require(job.status == Status.Open, "Job is not open");

    job.status = Status.Canceled;

    emit JobCanceled(jobId);
}


}