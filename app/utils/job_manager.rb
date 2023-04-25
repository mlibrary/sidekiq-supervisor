module JobManager
  extend self
  # Lists the unfinished jobs for a given string
  # @param str [String] String that matches something in the arguments string
  def queued_jobs(str=nil)
    _jobs(str).select{|j| j.status == "queued" }
  end

  def uncompleted_jobs(str = nil)
    _jobs(str).select{|j| j.status == "started" }
  end

  def completed_jobs(str = nil)
    _jobs(str).select{|j| j.status == "complete" }
  end

  def jobs(str = nil)
    _jobs(str)
  end
  def restart_uncompleted_jobs(str, sidekiq_client=Sidekiq::Client, logger=Logger.new($stdout))
    jobs = self.uncompleted_jobs(str)
    jobs.each do |j|
      logger.info "requeuing class => #{j.job_class}\tqueue => #{j.queue}\targs=>#{JSON.parse(j.arguments)}"
      sidekiq_client.push_bulk("class" => j.job_class, "queue" => j.queue, "args" => [JSON.parse(j.arguments)])
      j.destroy
    end
  end
  def queued_to_completion_duration(str = nil)
    completed_jobs(str).each do |j|
      if j.queued_to_completion_duration
        puts "#{human_readable_time(j.queued_to_completion_duration)}\tclass=>#{j.job_class}\tqueue => #{j.queue}\targs=>#{JSON.parse(j.arguments)}"
      end
    end
    return
  end
  def completed_jobs_duration(str = nil)
    completed_jobs(str).each do |j|
      if j.job_duration
        puts "#{human_readable_time(j.job_duration)}\tclass=>#{j.job_class}\tqueue => #{j.queue}\targs=>#{JSON.parse(j.arguments)}"
      end
    end
    return
  end
  private
  def _jobs(str)
    str.nil? ? Job.all : Job.for_job_string(str)
  end
  private
  def human_readable_time(secs)
    #from https://gist.github.com/emmahsax/af285a4b71d8506a1625a3e591dc993b
    [[60, :seconds], [60, :minutes], [24, :hours], [Float::INFINITY, :days]].map do |count, name|
    next unless secs > 0

    secs, number = secs.divmod(count)
    "#{number.to_i} #{number == 1 ? name.to_s.delete_suffix('s') : name}" unless number.to_i == 0
  end.compact.reverse.join(', ')
  end
end
