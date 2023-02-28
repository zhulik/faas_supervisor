# frozen_string_literal: true

class App::Docker::Registries::Docker < App::Docker::Registries::Registry
  include Memery

  private

  def connection = Faraday.new("https://registry-1.docker.io") { configure_connection(_1) }
  def token_connection = Faraday.new("https://auth.docker.io") { configure_connection(_1) }

  def token(name)
    token_connection.get("/token", {
                           service: "registry.docker.io",
                           scope: "repository:#{name}:pull"
                         }).body[:token]
  end
end
