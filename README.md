# README

This is a system for monitoring the completion of sidekiq jobs. 

## API Endpoints

This will create a job, and will mark it as queued

```
post /api/v1/jobs
```

Which takes in the following parameters
|  parameter| description |
|-----------|-------------|
| job_id    | the sidekiq job_id |
| arguments | the arguments used for the job |
| job_class | the class used for the job |
| queue     | the queue for the job |


This uses the sidekiq `job_id` to mark the job as having been started.

```
post /api/v1/jobs/:job_id/started
```
Which takes in the following parameters
|  parameter| description |
|-----------|-------------|
| arguments | the arguments used for the job |
| job_class | the class used for the job |
| queue     | the queue for the job |


This uses the sidekiq `job_id` to mark the job as done.

```
post /api/v1/jobs/:job_id/complete
```
Which takes in the following parameters
|  parameter| description |
|-----------|-------------|
| arguments | the arguments used for the job |
| job_class | the class used for the job |
| queue     | the queue for the job |


## How to add Sidekiq monitor to your application

These examples uses the [Faraday](https://lostisland.github.io/faraday/) gem to contact the supervior. Any means of
making http request is fine.

### Sidekiq Client / Queuer

Any application that queues jobs needs to have the following middleware to let
the supervisor know that a job has been queued:

```ruby
class JobQueued
  def call(worker, job, queue, redis_pool)
    response = Faraday.post("#{ENV.fetch("SIDEDIQ_SUPERVISOR_HOST")}/api/v1/jobs", {
      job_id: job["jid"],
      arguments: job["args"].to_json,
      job_class: job["class"],
      queue: queue
    })
    yield
  end
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add JobQueued
  end
end
```

### The Sidekiq Server / Worker
Each sidekiq worker (or server) needs to have the following middleware so they
can check in or out with the supervisor. 

```ruby
class CheckInCheckOut
  def call(worker, job, queue)
    response = Faraday.post("#{ENV.fetch("SIDEKIQ_SUPERVISOR_HOST")}/api/v1/jobs/#{job["jid"]}/started", {
      arguments: job["args"].to_json,
      job_class: job["class"],
      queue: queue
    })
    yield
    response = Faraday.post("#{ENV.fetch("SIDEKIQ_SUPERVISOR_HOST")}/api/v1/jobs/#{job["jid"]}/complete", {
      arguments: job["args"].to_json,
      job_class: job["class"],
      queue: queue
    })
  end
end


Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add CheckInCheckOut
  end
end

```

## Monitoring and requeuing jobs in the console

There is a `JobManager` with methods that help manage jobs that have checked in
with the supervisor. Every method takes in an optional string that filters the
results based on if the string matches something in the arguments for the job.

```ruby
bundle exec rails c

# Shows a list of jobs whose most recent status is "queued". 
JobManager.queued_jobs("optional string")


# Shows a list of jobs whose most recent status is "started". 
JobManager.uncompleted_jobs("optional string")

# Shows a list of jobs whose most recent status is "complete".
JobManager.completed_jobs("optional string")


# Shows a list of all jobs. 
JobManager.jobs("optional string")

# Displays a list of jobs and how long it took for the job to go from queued to completed
JobManager.queued_to_completion_duration("optional string")


# Displays a list of jobs and how long it took for the job to go from started to completed
JobManager.completed_jobs_duration("optional string")

# Queues uncompleted jobs. Deletes the original job from the database.
# restart_uncompleted_jobs("optional string")
```

## Sidekiq monitor gui
The route `/sidekiq` goes to the sidekiq monitoring app.
