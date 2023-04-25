# README

This is a system for monitoring the completion of sidekiq jobs. 

There are two api endpoints

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

This will create a job, and will mark it as started

```
post /api/v1/jobs/:job_id/started
```
Which takes in the following parameters
|  parameter| description |
|-----------|-------------|
| arguments | the arguments used for the job |
| job_class | the class used for the job |
| queue     | the queue for the job |

This uses the sidekiq `job_id` to mark the job as having been started.

```
post /api/v1/jobs/:job_id/complete
```
Which takes in the following parameters
|  parameter| description |
|-----------|-------------|
| arguments | the arguments used for the job |
| job_class | the class used for the job |
| queue     | the queue for the job |

This uses the sidekiq `job_id` to mark the job as done.

## How to add Sidekiq monitor to your application

These examples uses the Faraday gem to contact the supervior. Any means of
making http request is fine.

### Sidekiq Client / Queuer

Any application that queues jobs needs to have the following middleware:

```
class JobQueued
  def call(worker, job, queue, redis_pool)
    response = Faraday.post("#{ENV.fetch("INDEXING_MONITOR_HOST")}/api/v1/jobs", {
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
Your sidekiq workers (or server) needs to have the following middleware so they
can check with the supervisor. 

```
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
  Yabeda::Prometheus::Exporter.start_metrics_server!
  config.server_middleware do |chain|
    chain.add CheckInCheckOut
  end
end

```

