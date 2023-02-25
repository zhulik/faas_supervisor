# frozen_string_literal: true

class FaasSupervisor::Deployer
  include FaasSupervisor::Helpers

  option :function, type: T.Instance(Openfaas::Function)
  inject :kubernetes

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

    updated_images = images.map { async_fetch_digest_for(_1) }
                           .map(&:wait)
                           .reduce(&:merge)
                           .reject { _1.digest == _2 }

    return debug { "Function has not been updated. Nothing to do." } if updated_images.empty?

    restart_deployment!
  rescue StandardError => e
    warn(e)
  end

  def published_digest(image) = registry(image).published_digest(name: image.full_name, tag: image.tag)
  memoize def registry(image) = FaasSupervisor::Docker::RegistryFactory.build(image.registry)

  def deployment = kubernetes.apps_v1_api.read_apps_v1_namespaced_deployment(function.name, function.namespace)
  def pods = kubernetes.core_v1_api.list_core_v1_namespaced_pod(function.namespace, label_selector:).items
  def label_selector = deployment.spec.selector.match_labels.map { "#{_1}=#{_2}" }.join(",")

  def images
    pods.flat_map { _1.status.container_statuses }
        .map { Image.new(image: _1.image, image_id: _1.image_id) }
        .uniq
  end

  def async_fetch_digest_for(image) = Async { { image => published_digest(image) } }

  def restart_deployment!
    info { "Function image has been updated, restarting deployment..." }
    # kubernetes.apps_v1_api.patch_apps_v1_namespaced_deployment(function.name, function.namespace, restart_annotations)
    # TODO: wait for images to be updated
    info { "Deployment restarted" }
  end

  def restart_annotations
    [
      {
        op: "replace",
        path: "/spec/template/metadata/annotations/faas_supervisor.restartedAt",
        value: Time.now
      }
    ]
  end
end
