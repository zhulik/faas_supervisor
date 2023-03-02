# frozen_string_literal: true

class App::Deployer
  include App::Helpers

  include Bus::Publisher

  WAIT_UPDATE_ATTEMPS = 10
  WAIT_UPDATE_INTERVAL = 5

  option :deployment_name, type: T::Strict::String
  option :namespace, type: T::Strict::String
  option :interval, type: T::Strict::Float

  inject :kubernetes

  def run
    Async::Timer.new(interval, run_on_start: true, call: self, on_error: ->(e) { warn(e) })
    info { "Started, update interval: #{interval}" }
  end

  # TODO: add timeout
  def call
    debug { "Checking..." }

    return debug { "Update is in progress. Nothing to do." } if @wait_task

    warn { "Cannot find digests, deployment with 0 replicas?" } if digests.empty?

    updated_images = digests.reject { _2[:deployed] == _2[:published] }

    return debug { "Deployment image has not been updated. Nothing to do." } if updated_images.empty?

    publish_event("kubernetes.application.published_image_updated", kind: "deployment",
                                                                    name: deployment_name,
                                                                    namespace:)

    @wait_task = Async { restart_deployment!(updated_images) }
  end

  private

  def logger_info = "Deployment = #{deployment_name.inspect}"

  def published_digest(image) = registry(image).published_digest(name: image.full_name, tag: image.tag)
  memoize def registry(image) = App::Docker::RegistryFactory.build(image.registry)

  memoize def deployment = kubernetes.apps_v1_api.read_apps_v1_namespaced_deployment(deployment_name, namespace)
  def label_selector = deployment.spec.selector.match_labels.map { "#{_1}=#{_2}" }.join(",")

  def images
    kubernetes.core_v1_api
              .list_core_v1_namespaced_pod(namespace, label_selector:)
              .items
              .reject { _1.metadata.deletion_timestamp }
              .flat_map { _1.status.container_statuses }
              .map { Image.new(image: _1.image, image_id: _1.image_id) }
              .uniq
  end

  def digests
    images.map { async_fetch_digest_for(_1) }
          .map(&:wait)
          .reduce(&:merge) || []
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
    @wait_task = nil

    publish_event("kubernetes.application.restarted", kind: "deployment",
                                                      name: deployment_name,
                                                      namespace:)
  end

  def restart_annotations
    [
      {
        op: "add",
        path: "/spec/template/metadata/annotations",
        value: { "faas_supervisor.restartedAt": Time.now }
      }
    ]
  end

  # TODO: use watch
  def wait_for_restart(updates)
    WAIT_UPDATE_ATTEMPS.times do |attempt|
      debug { "Wait restart attempt #{attempt + 1}" }

      return info { "Deployment restarted" } if images.all? { _1.digest == updates[_1.image][:published] }

      sleep(WAIT_UPDATE_INTERVAL)
    end
    warn { "Can't wait for deployment restart, maximum attempts reached" }
  end
end
