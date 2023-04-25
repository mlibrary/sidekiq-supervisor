require "rails_helper"

RSpec.describe Status, type: :model do
  context "name" do
    it "has :queued for 0" do
      j = create(:job)
      s = Status.create(name: 0, job: j)
      expect(s.name).to eq("queued")
    end
  end
  context "name" do
    it "has :started for 1" do
      j = create(:job)
      s = Status.create(name: 1, job: j)
      expect(s.name).to eq("started")
    end
  end
  context "name" do
    it "has :complete for 2" do
      j = create(:job)
      s = Status.create(name: 2, job: j)
      expect(s.name).to eq("complete")
    end
  end
end
