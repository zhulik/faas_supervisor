# frozen_string_literal: true

RSpec.describe App do
  it "has a version number" do
    expect(App::VERSION).not_to be_nil
  end
end
