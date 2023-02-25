# frozen_string_literal: true

class FaasSupervisor::Deployer
  include FaasSupervisor::Helpers

  option :function, type: T.Instance(Openfaas::Function)
  inject :kubernetes

  class Image < Dry::Struct
    attribute :image, FaasSupervisor::Deployer::T::String
    attribute :image_id, FaasSupervisor::Deployer::T::String
  end

  def run
    timer.start
    info { "Started, update interval: #{config.interval}" }
  end

  def stop
    timer.stop
    info { "Stopped" }
  end

  private

  memoize def timer = Async::Timer.new(config.interval, start: false, run_on_start: true) { cycle }

  def logger_info = "Function = #{function.name.inspect}"
  def config = function.supervisor_config.autodeployment

  # TODO: add timeout
  def cycle
    debug { "Checking..." }
    info { images }
  rescue StandardError => e
    warn(e)
  end

  memoize def deployment = kubernetes.apps_v1_api.read_apps_v1_namespaced_deployment(function.name, function.namespace)

  def pods
    label_selector = deployment.spec.selector.match_labels.map { "#{_1}=#{_2}" }.join(",")
    kubernetes.core_v1_api.list_core_v1_namespaced_pod(function.namespace, label_selector:).items
  end

  def images
    pods.flat_map do |pod|
      pod.status.container_statuses.map do |status|
        Image.new(
          image: status.image,
          image_id: status.image_id
        )
      end
    end.uniq
  end
end
