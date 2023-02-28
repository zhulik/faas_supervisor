# frozen_string_literal: true

RSpec.describe App::IntervalParser do
  describe ".parse" do
    subject { described_class.parse(str) }

    {
      "10s" => 10,
      "10m" => 600,
      "10.5h" => 37_800.0,
      "1d" => 86_400
    }.each do |interval, result|
      context "when interval=#{interval}" do
        let(:str) { interval }

        it "returns interval in seconds" do
          expect(subject).to eq(result)
        end
      end
    end

    context "when argument has unknown unit" do
      let(:str) { "10w" }

      it "raises ArgumentError" do
        expect { subject }.to raise_error(ArgumentError, "unknown unit w")
      end
    end

    context "when argument has invalid unit" do
      let(:str) { "10blah" }

      it "raises ArgumentError" do
        expect { subject }.to raise_error(ArgumentError, "cannot parse 10blah")
      end
    end

    context "when argument is not a duration" do
      let(:str) { "blahblah" }

      it "raises ArgumentError" do
        expect { subject }.to raise_error(ArgumentError, "cannot parse blahblah")
      end
    end

    context "when argument is 0 duration" do
      let(:str) { "0m" }

      it "raises ArgumentError" do
        expect { subject }.to raise_error(ArgumentError, "interval cannot be 0")
      end
    end

    context "when argument is not a string" do
      let(:str) { [] }

      it "raises ArgumentError" do
        expect { subject }.to raise_error(ArgumentError, "argument must be a string")
      end
    end
  end
end
