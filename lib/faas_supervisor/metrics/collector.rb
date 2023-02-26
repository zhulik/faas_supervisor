# frozen_string_literal: true

class FaasSupervisor::Metrics::Collector
  include FaasSupervisor::Helpers

  option :parent, type: T.Interface(:async)

  inject :metrics_store

  INTERVAL = 2

  def run
    timer.start
    info { "Started" }
  end

  private

  memoize def timer = Async::Timer.new(INTERVAL, start: false, run_on_start: true, parent:) { cycle }

  def cycle # rubocop:disable Metrics/AbcSize
    metrics_store.set("ruby_fibers", fibers.count)
    metrics_store.set("ruby_fibers_active", fibers.count(&:alive?))
    metrics_store.set("ruby_threads", threads.count)
    metrics_store.set("ruby_threads_active", threads.count(&:alive?))
    metrics_store.set("ruby_ractors", ractors.count)

    metrics_store.set("ruby_memory", GetProcessMem.new.bytes.to_s("F"), suffix: "bytes")
  rescue StandardError => e
    warn(e)
  end

  def fibers = ObjectSpace.each_object(Fiber)
  def threads = ObjectSpace.each_object(Thread)
  def ractors = ObjectSpace.each_object(Ractor)
end
