pragma solidity >=0.4.22 <0.9.0;

contract JobMarketplace {
    address public owner;
    uint public jobCount;

    enum Status { Open, InProgress, Completed, Canceled }

    struct Job {
        uint id;
        string title;
        string description;
        uint payment;
        address client;
        address freelancer;
        Status status;
    }

    mapping(uint => Job) public jobs;

    event JobPosted(uint jobId, string title, string description, uint payment, address client);
    event JobBid(uint jobId, address freelancer);
    event JobAccepted(uint jobId, address freelancer);
    event JobCompleted(uint jobId);
    event JobCanceled(uint jobId);

    constructor() {
        owner = msg.sender;
    }

    function postJob(string memory _title, string memory _description, uint _payment) public {
        require(bytes(_title).length > 0, "Job title cannot be empty");
        require(bytes(_description).length > 0, "Job description cannot be empty");
        require(_payment > 0, "Payment must be greater than 0");

        jobCount++;
        jobs[jobCount] = Job(jobCount, _title, _description, _payment, msg.sender, address(0), Status.Open);

        emit JobPosted(jobCount, _title, _description, _payment, msg.sender);
    }

    function bidOnJob(uint _jobId) public {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        Job storage job = jobs[_jobId];
        require(msg.sender != job.client, "Client cannot bid on their own job");
        require(job.status == Status.Open, "Job is not open for bidding");

        job.freelancer = msg.sender;

        emit JobBid(_jobId, msg.sender);
    }

    function acceptBid(uint _jobId) public {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        Job storage job = jobs[_jobId];
        require(msg.sender == job.client, "Only the client can accept a bid");
        require(job.status == Status.Open, "Job is not open for accepting bids");
        require(job.freelancer != address(0), "No freelancer has bid on this job");

        job.status = Status.InProgress;

        emit JobAccepted(_jobId, job.freelancer);
    }

    function markJobCompleted(uint _jobId) public {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        Job storage job = jobs[_jobId];
        require(msg.sender == job.freelancer, "Only the freelancer can mark the job as completed");
        require(job.status == Status.InProgress, "Job is not in progress");

        job.status = Status.Completed;

        emit JobCompleted(_jobId);
    }

    function cancelJob(uint _jobId) public {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        Job storage job = jobs[_jobId];
        require(msg.sender == job.client, "Only the client can cancel the job");
        require(job.status == Status.Open, "Job is not open");

        job.status = Status.Canceled;

        emit JobCanceled(_jobId);
    }
}