require 'spec_helper'

describe Shellout do
  let(:command) { 'echo foo' }

  subject { described_class.new(command) }

  describe '#run' do
    it 'returns output of shell command' do
      expect(subject.run).to eq('foo')
    end
  end

  describe '#try_run' do
    let(:command) { 'foo bar' }

    it 'returns empty string' do
      expect(subject.try_run).to eq('')
    end

    it 'does not raise error' do
      expect{subject.try_run}.not_to raise_error
    end
  end

  describe '#read_stdout' do
    before do
      subject.run
    end

    it 'returns stdout of shell command' do
      expect(subject.read_stdout).to eq('foo')
    end
  end

  describe '#read_stderr' do
    let(:command) { 'echo error 1>&2; exit 1' }

    before do
      subject.run
    end

    it 'returns stdout of shell command' do
      expect(subject.read_stderr).to eq('error')
    end
  end

  describe '#success?' do
    before do
      subject.run
    end

    context 'when command is successful' do
      it 'returns true' do
        expect(subject.success?).to be true
      end
    end

    context 'when command is not successful' do
      let(:command) { 'echo error 1>&2; exit 1' }

      it 'returns false' do
        expect(subject.success?).to be false
      end
    end
  end
end
