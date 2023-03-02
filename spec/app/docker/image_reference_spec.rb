# frozen_string_literal: true

RSpec.describe App::Docker::ImageReference do
  let(:reference) { described_class.new(name) }

  DIGEST = "sha256:e2e16842c9b54d985bf1ef9242a313f36b856181f188de21313820e177002501" # rubocop:disable Lint/ConstantDefinitionInBlock,RSpec/LeakyConstantDeclaration

  shared_examples("returns normalized string representation") do |input, output|
    context "when input=#{input.inspect}" do
      let(:name) { input }

      it "returns normalized string representation" do
        expect(subject).to eq(output)
      end
    end
  end

  describe "#to_s" do
    subject { reference.to_s }

    {
      "docker.io/library/alpine:latest" => [
        "alpine",
        "alpine:latest",
        "library/alpine:latest"
      ],
      "docker.io/library/alpine@#{DIGEST}" => [
        "alpine@#{DIGEST}",
        "library/alpine@#{DIGEST}"
      ],
      "ghcr.io/library/alpine:latest" => ["ghcr.io/library/alpine"],
      "ghcr.io/library/alpine@#{DIGEST}" => []
    }.each do |output, inputs|
      include_examples "returns normalized string representation", output, output

      inputs.each { include_examples "returns normalized string representation", _1, output }
    end
  end
end
