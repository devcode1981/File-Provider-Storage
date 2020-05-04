# frozen_string_literal: true

require 'spec_helper'

describe GDK::Diagnostic::Re2 do
  describe '#diagnose' do
    context 'when re2 is not installed or bad' do
      it 'returns error' do
        stub_shellout(false, stderr: 'cannot load such file -- re2 (LoadError)')

        expect(subject.diagnose).to eq('error')
      end
    end

    context 'when re2 is OK' do
      it 'returns nil' do
        stub_shellout(true)

        expect(subject.diagnose).to be_nil
      end
    end
  end

  describe '#success?' do
    context 'when re2 is not installed or bad' do
      it 'returns false' do
        stub_shellout(false, stderr: 'cannot load such file -- re2 (LoadError)')

        subject.diagnose

        expect(subject.success?).to be(false)
      end
    end

    context 'when re2 is OK' do
      it 'returns true' do
        stub_shellout(true)

        subject.diagnose

        expect(subject.success?).to be(true)
      end
    end
  end

  describe '#detail' do
    context 'when re2 is not installed or bad' do
      it 'returns false' do
        stub_shellout(false, stderr: 'cannot load such file -- re2 (LoadError)')

        subject.diagnose

        expect(subject.detail).to eq("It looks like your system re2 library may have been upgraded, and\nthe re2 gem needs to be rebuilt as a result.\n\nPlease run `gem pristine re2`.\n")
      end
    end

    context 'when re2 is OK' do
      it 'returns nil' do
        stub_shellout(true)

        subject.diagnose

        expect(subject.detail).to be_nil
      end
    end
  end

  def stub_shellout(success, stdout: '', stderr: '')
    shellout = double('Shellout', try_run: nil, read_stdout: stdout, read_stderr: stderr, success?: success)
    allow(Shellout).to receive(:new).with(['ruby', '-e', "require 're2'; regexp = RE2::Regexp.new('{', log_errors: false); regexp.error unless regexp.ok?"]).and_return(shellout)
  end
end
