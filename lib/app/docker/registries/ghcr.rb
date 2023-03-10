# frozen_string_literal: true

class App::Docker::Registries::Ghcr < App::Docker::Registries::Registry
  private

  def connection = Faraday.new("https://ghcr.io") { configure_connection(_1) }

  def token(reference)
    connection.get("/token", {
                     service: "ghcr.io",
                     scope: "scope=repository:#{reference.full_name}:pull"
                   }).body[:token]
  end
end
