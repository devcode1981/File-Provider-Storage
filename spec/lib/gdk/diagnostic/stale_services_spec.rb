# frozen_string_literal: true

require 'spec_helper'

describe GDK::Diagnostic::StaleServices do
  let(:stale_processes) do
    <<~STALE_PROCESSES
      95010 runsv rails-web
      95011 runsv rails-actioncable
    STALE_PROCESSES
  end

  describe '#diagnose' do
    it 'returns nil' do
      expect(subject).to receive_message_chain(:ps_command, :try_run)

      expect(subject.diagnose).to be_nil
    end
  end

  describe '#success?' do
    before do
      stub_ps(output, success: success)
    end

    context 'but ps fails' do
      let(:success) { false }

      it 'returns true' do
        expect(subject).to be_success
      end
    end

    context 'and ps succeeds' do
      let(:success) { true }

      context 'and there are no stale processes' do
        let(:output) { '' }

        it 'returns true' do
          expect(subject).to be_success
        end
      end

      context 'but there are stale processes' do
        let(:output) { stale_processes }

        it 'returns false' do
          expect(subject).not_to be_success
        end
      end
    end
  end

  describe '#detail' do
    before do
      stub_ps(output, success: success)
    end

    context 'but ps fails' do
      let(:output) { nil }
      let(:success) { false }

      it 'returns nil' do
        expect(subject.detail).to be_nil
      end
    end

    context 'and ps succeeds' do
      let(:success) { true }

      context 'and there are no stale processes' do
        let(:output) { '' }

        it 'returns nil' do
          expect(subject.detail).to be_nil
        end
      end

      context 'but there are stale processes' do
        let(:output) { stale_processes }

        it 'returns help message' do
          expect(subject.detail).to eq("The following GDK services appear to be stale:\n\nrails-web\nrails-actioncable\n\nYou can try killing them by running:\n\nkill 95010 95011\n")
        end
      end
    end
  end

  def stub_ps(result, success: true)
    shellout = double('Shellout', try_run: result, read_stdout: result, success?: success)
    full_command = %(pgrep -l -P 1 -f "runsv (elasticsearch|geo-cursor|gitaly|gitlab-pages|gitlab-workhorse|grafana|jaeger|mattermost|minio|nginx|openldap|postgresql|praefect|prometheus|registry|rails-actioncable|rails-background-jobs|rails-web|redis|runner|sshd|tunnel_|webpack)")
    allow(Shellout).to receive(:new).with(full_command).and_return(shellout)
    allow(shellout).to receive(:try_run).and_return(result)
  end
end
