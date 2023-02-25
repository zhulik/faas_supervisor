# frozen_string_literal: true

class FaasSupervisor::Docker::Registries::Ghcr < FaasSupervisor::Docker::Registries::Registry
  private

  def connection = Faraday.new("https://ghcr.io") { configure_connection(_1) }

  def token(name)
    connection.get("/token", {
                     service: "ghcr.io",
                     scope: "scope=repository:#{name}:pull"
                   }).body[:token]
  end
end
