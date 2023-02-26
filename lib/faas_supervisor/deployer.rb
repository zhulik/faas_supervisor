# frozen_string_literal: true

class FaasSupervisor::Deployer
  include FaasSupervisor::Helpers

  WAIT_UPDATE_ATTEMPS = 10
  WAIT_UPDATE_INTERVAL = 5

  option :deployment_name, type: T::String
  option :namespace, type: T::String
  option :interval, type: T::Float

  inject :kubernetes

  def run
    timer.start
    info { "Started, update interval: #{interval}" }
  end

  def stop
    timer.stop
    info { "Stopped" }
  end

  private

  memoize def timer = Async::Timer.new(interval, start: false, run_on_start: true) { cycle }

  def logger_info = "Deployment = #{deployment_name.inspect}"

  # TODO: add timeout
  def cycle
    debug { "Checking..." }

    updated_images = images.map { async_fetch_digest_for(_1) }
                           .map(&:wait)
                           .reduce(&:merge)
                           .reject { _2[:deployed] == _2[:published] }

    return debug { "Deployment image has not been updated. Nothing to do." } if updated_images.empty?

    restart_deployment!(updated_images) if deployment_name == "databases-backups-stats-collector"
  rescue StandardError => e
    warn(e)
  end

  def published_digest(image) = registry(image).published_digest(name: image.full_name, tag: image.tag)
  memoize def registry(image) = FaasSupervisor::Docker::RegistryFactory.build(image.registry)

  memoize def deployment = kubernetes.apps_v1_api.read_apps_v1_namespaced_deployment(deployment_name, namespace)
  def label_selector = deployment.spec.selector.match_labels.map { "#{_1}=#{_2}" }.join(",")

  def running_pods
    kubernetes.core_v1_api
              .list_core_v1_namespaced_pod(namespace, label_selector:)
              .items
              .reject { _1.metadata.deletion_timestamp }
  end

  def images
    running_pods.flat_map { _1.status.container_statuses }
                .map { Image.new(image: _1.image, image_id: _1.image_id) }
                .uniq
  end

  def async_fetch_digest_for(image)
    Async do
      {
        image.image => {
          published: published_digest(image),
          deployed: image.digest
        }
      }
    end
  end

  def restart_deployment!(updates)
    info { "Deployment image has been updated, restarting deployment..." }
    kubernetes.apps_v1_api.patch_apps_v1_namespaced_deployment(deployment_name, namespace, restart_annotations)

    info { "Waiting for restart, interval=#{WAIT_UPDATE_INTERVAL}, attempts=#{WAIT_UPDATE_ATTEMPS}" }
    wait_for_restart(updates)
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

  # TODO: notifications
  def wait_for_restart(updates)
    WAIT_UPDATE_ATTEMPS.times do |attempt|
      debug { "Wait restart attempt #{attempt + 1}" }

      return info { "Deployment restarted" } if images.all? { _1.digest == updates[_1.image][:published] }

      sleep(WAIT_UPDATE_INTERVAL)
    end
    warn { "Can't wait for deployment restart, maximum attempts reached" }
  end
end
