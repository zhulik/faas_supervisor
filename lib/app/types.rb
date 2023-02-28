# frozen_string_literal: true

module App::Types
  include Dry.Types

  StringLike = (Strict::String | Strict::Symbol).constructor(&:to_s)
  KV = Strict::Hash.map(StringLike, Strict::String)
end
