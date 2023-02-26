# frozen_string_literal: true

class FaasSupervisor::Openfaas::Client
  include FaasSupervisor::Helpers

  option :url, type: T::Strict::String
  option :username, type: T::Strict::String
  option :password, type: T::Strict::String

  def scale(name, replicas) = connection.post("/system/scale-function/#{name}", { replicas: }).success?
  def function(name) = get("/system/function/#{name}", Openfaas::Function)
  def functions = get_list("/system/functions", Openfaas::Function)

  def get(url, klass) = connection.get(url).body.then { klass.new(_1) }
  def get_list(url, klass) = connection.get(url).body.map { klass.new(_1) }

  def close = connection.close

  private

  memoize def connection
    Faraday.new(url) do |f|
      f.request :authorization, :basic, username, password
      f.request :json

      f.response :raise_error
      f.response :json, parser_options: { symbolize_names: true }
    end
  end
end
