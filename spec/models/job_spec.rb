require "rails_helper"

RSpec.describe Job, type: :model do
  it "has an id, class, and arguments" do
    j = create(:job)
    expect(j.job_id).to eq("job_id")
    expect(j.job_class).to eq("job_class")
    expect(j.arguments).to eq("arguments")
    expect(j.queue).to eq("queue")
  end
  it "only allows unique job ids" do
    create(:job, job_id: 1)
    j = build(:job, job_id: 1)
    expect(j.valid?).to eq(false)
  end
  context "#job_duration" do
    it "shows the duration between that latest job start and finish" do
      j = create(:job)
      create(:status, job: j, name: "started", created_at: "2023-04-12 01:00:00Z")
      create(:status, job: j, name: "started", created_at: "2023-04-12 01:10:00Z")
      create(:status, job: j, name: "complete", created_at: "2023-04-12 01:20:00Z")
      expect(j.job_duration).to eq(10 * 60)
    end
    it "returns nil if the job is only queued" do
      j = create(:job)
      create(:status, job: j, name: "queued")
      expect(j.job_duration).to be_nil
    end
    it "returns nil if the job is only queued and started" do
      j = create(:job)
      create(:status, job: j, name: "queued")
      create(:status, job: j, name: "started")
      expect(j.job_duration).to be_nil
    end
  end
  context "#queued_to_completion_duration" do
    it "shows the duration from queue time to finish" do
      j = create(:job)
      create(:status, job: j, name: "queued", created_at: "2023-04-12 01:00:00Z")
      create(:status, job: j, name: "started", created_at: "2023-04-12 01:05:00Z")
      create(:status, job: j, name: "started", created_at: "2023-04-12 01:10:00Z")
      create(:status, job: j, name: "complete", created_at: "2023-04-12 01:20:00Z")
      expect(j.queued_to_completion_duration).to eq(20 * 60)
    end
  end
end
