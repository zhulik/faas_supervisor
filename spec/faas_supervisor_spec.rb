# frozen_string_literal: true

RSpec.describe FaasSupervisor do
  it "has a version number" do
    expect(FaasSupervisor::VERSION).not_to be_nil
  end
end
