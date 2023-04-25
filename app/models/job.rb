class Job < ApplicationRecord
  has_many :statuses, dependent: :destroy
  validates :job_id, :arguments, :job_class, :queue, presence: true
  validates :job_id, uniqueness: true

  def self.for_job_string(str)
    Job.select do |j|
      j.arguments.match?(str)
    end
  end

  def status
    statuses.order(:created_at).last.name
  end

  def queued_to_completion_duration
    queued = statuses.find_by(name: "queued")
    completed = statuses.find_by(name: "complete")
    return if completed.nil?
    completed.created_at - queued.created_at
  end

  def job_duration
    started = statuses.where(name: "started").order(:created_at).last
    completed = statuses.find_by(name: "complete")
    return if started.nil? || completed.nil?
    completed.created_at - started.created_at
  end
end
