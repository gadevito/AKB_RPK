// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marketplace {
    // State variables
    address public owner;
    uint public jobCount = 0;
    mapping(uint => Job) public jobs;

    struct Job {
        uint id;
        string title;
        string description;
        uint payment;
        address client;
        address freelancer;
        Status status;
    }

    enum Status {
        Open,
        InProgress,
        Completed,
        Canceled
    }

    // Events
    event JobPosted(uint indexed id, string title, address indexed client);
    event JobBid(uint indexed id, address indexed freelancer);
    event JobAccepted(uint indexed id);
    event JobCompleted(uint indexed id);
    event JobCanceled(uint indexed id);

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // Function to post a new job
    function postJob(
        string memory _title,
        string memory _description,
        uint _payment
    ) public {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_payment > 0, "Payment must be greater than 0");

        jobCount++;
        jobs[jobCount] = Job(
            jobCount,
            _title,
            _description,
            _payment,
            msg.sender,
            address(0),
            Status.Open
        );
        emit JobPosted(jobCount, _title, msg.sender);
    }

    // Function to bid on a job
    function bidOnJob(uint _jobId) public {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        Job storage job = jobs[_jobId];
        require(job.status == Status.Open, "Job is not open");
        require(
            msg.sender != job.client,
            "Clients cannot bid on their own jobs"
        );

        job.freelancer = msg.sender;
        job.status = Status.InProgress;
        emit JobBid(_jobId, msg.sender);
    }

    // Function to accept a bid and start the job
    function acceptBid(uint _jobId) public {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        Job storage job = jobs[_jobId];
        require(msg.sender == job.client, "Only the client can accept a bid");
        require(job.status == Status.InProgress, "Job is not in progress");

        job.status = Status.Completed;
        emit JobAccepted(_jobId);
    }

    // Function to mark a job as completed
    function markJobCompleted(uint _jobId) public {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        Job storage job = jobs[_jobId];
        require(
            msg.sender == job.freelancer,
            "Only the freelancer can mark the job as completed"
        );
        require(job.status == Status.InProgress, "Job is not in progress");

        job.status = Status.Completed;
        emit JobCompleted(_jobId);
    }

    // Function to cancel a job
    function cancelJob(uint _jobId) public {
        require(_jobId > 0 && _jobId <= jobCount, "Invalid job ID");
        Job storage job = jobs[_jobId];
        require(
            msg.sender == job.freelancer,
            "Only the freelancer can cancel the job"
        );
        require(job.status == Status.Open, "Job is not open");

        job.status = Status.Canceled;
        emit JobCanceled(_jobId);
    }
}
