class Status < ApplicationRecord
  belongs_to :job
  enum name: { queued: 0, started: 1, complete: 2 }
end
