require 'spec_helper'
require 'stringio'

describe GDK::Command::Doctor do
  let(:mock_stdout) { double(:stdout, puts: nil) }
  let(:mock_stderr) { double(:stderr, puts: nil) }
  let(:successful_diagnostic) { double(GDK::Diagnostic, success?: true, diagnose: nil) }
  let(:failing_diagnostic) { double(GDK::Diagnostic, success?: false, diagnose: 'error', message: 'check failed') }
  let(:diagnostics) { [] }
  let(:warning_message) { 'This is a warning' }

  subject { described_class.new(stdout: mock_stdout, stderr: mock_stderr) }

  before do
    allow(subject).to receive(:gdk_start)
    allow(subject).to receive(:diagnostics).and_return(diagnostics)
    allow(subject).to receive(:warning).and_return(warning_message)
  end

  it 'starts gdk' do
    expect(subject).to receive(:gdk_start)
    subject.run
  end

  context 'with passing diagnostics' do
    let(:diagnostics) { [successful_diagnostic, successful_diagnostic] }

    it 'runs all diagnosis' do
      expect(successful_diagnostic).to receive(:diagnose).twice
      subject.run
    end

    it 'prints GDK is ready.' do
      expect(mock_stdout).to receive(:puts).with('GDK is healthy.')
      subject.run
    end
  end

  context 'with failing diagnostics' do
    let(:diagnostics) { [failing_diagnostic, failing_diagnostic] }

    it 'runs all diagnosis' do
      expect(failing_diagnostic).to receive(:diagnose).twice
      subject.run
    end

    it 'prints a warning' do
      expect(mock_stdout).to receive(:puts).with(warning_message).ordered
      expect(mock_stdout).to receive(:puts).with('check failed').ordered.twice
      subject.run
    end
  end
end
