# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

describe GDK::Command::Doctor do
  let(:mock_stdout) { double(:stdout, puts: nil) }
  let(:mock_stderr) { double(:stderr, puts: nil) }
  let(:successful_diagnostic) { double(GDK::Diagnostic, success?: true, diagnose: nil, message: nil) }
  let(:failing_diagnostic) { double(GDK::Diagnostic, success?: false, diagnose: 'error', message: 'check failed') }
  let(:diagnostics) { [] }
  let(:warning_message) { 'This is a warning' }
  let(:shellout) { double(Shellout, run: nil) }

  subject { described_class.new(diagnostics: diagnostics, stdout: mock_stdout, stderr: mock_stderr) }

  before do
    allow(Shellout).to receive(:new).with('gdk start postgresql').and_return(shellout)
    allow(subject).to receive(:warning).and_return(warning_message)
  end

  it 'starts necessary services' do
    expect(shellout).to receive(:run)

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

  context 'with partial failing diagnostics' do
    let(:diagnostics) { [failing_diagnostic, successful_diagnostic, failing_diagnostic] }

    it 'runs all diagnosis' do
      expect(failing_diagnostic).to receive(:diagnose).twice
      expect(successful_diagnostic).to receive(:diagnose).once
      subject.run
    end

    it 'prints a message from failed diagnostics' do
      expect(failing_diagnostic).to receive(:message).twice
      expect(mock_stdout).to receive(:puts).with(warning_message).ordered
      expect(mock_stdout).to receive(:puts).with('check failed').ordered.twice
      subject.run
    end

    it 'does not print a message from successful diagnostics' do
      expect(successful_diagnostic).not_to receive(:message)
      subject.run
    end
  end
end
