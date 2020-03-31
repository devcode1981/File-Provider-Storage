# frozen_string_literal: true

require 'spec_helper'

describe GDK::Diagnostic::Git do
  describe '#diagnose' do
    context 'when git is not installed' do
      it 'returns nil' do
        stub_version('', success: false)

        expect(subject.diagnose).to be_nil
      end
    end

    context 'when git is installed' do
      it 'returns the version' do
        installed_version = '2.26.0'

        stub_version(installed_version)

        expect(subject.diagnose).to eql(installed_version)
      end
    end
  end

  describe '#success?' do
    context 'when git is not installed' do
      it 'returns false' do
        stub_version('', success: false)

        expect(subject.success?).to be_falsy
      end
    end

    context 'when git is installed' do
      context 'and it is too old' do
        it 'returns false' do
          installed_version = '2.21.0'

          stub_version(installed_version)

          expect(subject.success?).to be_falsy
        end
      end

      context 'and it is equal to the minimum' do
        it 'returns false' do
          installed_version = described_class::MINIMUM_VERSION

          stub_version(installed_version)

          expect(subject.success?).to be_falsy
        end
      end

      context 'and it is equal to the recommended' do
        it 'returns true' do
          installed_version = described_class::RECOMMENDED_VERSION

          stub_version(installed_version)

          expect(subject.success?).to be_truthy
        end
      end

      context 'and it is newer than the minimum' do
        it 'returns true' do
          installed_version = '3.0.0'

          stub_version(installed_version)

          expect(subject.success?).to be_truthy
        end
      end
    end
  end

  describe '#detail' do
    context 'when git is not installed' do
      it 'returns a cannot determine git version message' do
        expected_message = 'Cannot determine Git version, is git installed?'

        stub_version('', success: false)

        expect(subject.detail).to eql(expected_message)
      end
    end

    context 'when git is installed' do
      context 'and it is too old' do
        it 'return a too old message' do
          expected_message = 'Git version 2.21.0 is too old.  You need at least 2.22.0.'

          stub_version('2.21.0')

          expect(subject.detail).to eql(expected_message)
        end
      end

      context 'and it is equal to the minimum' do
        it 'returns an OK but not the recommended version message' do
          expected_message = 'Git version 2.22.0 is OK but at least 2.26.0 is recommended.'

          stub_version(described_class::MINIMUM_VERSION)

          expect(subject.detail).to eql(expected_message)
        end
      end

      context 'and it is equal to the recommended' do
        it 'returns no message' do
          stub_version(described_class::RECOMMENDED_VERSION)

          expect(subject.detail).to be_nil
        end
      end

      context 'and it is newer than the minimum' do
        it 'returns no message' do
          stub_version('3.0.0')

          expect(subject.detail).to be_nil
        end
      end
    end
  end

  def stub_version(version, success: true)
    shellout = double('Shellout', try_run: version, read_stdout: version, success?: success)
    allow(Shellout).to receive(:new).with(%w[git --version]).and_return(shellout)
    allow(shellout).to receive(:try_run).and_return(version)
  end
end
