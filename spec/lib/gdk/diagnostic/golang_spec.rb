# frozen_string_literal: true

require 'spec_helper'

describe GDK::Diagnostic::Golang do
  describe '#diagnose' do
    it 'returns nil' do
      expect(subject.diagnose).to be_nil
    end
  end

  describe '#success?' do
    let(:go_get_success) { nil }

    before do
      stub_clone_exists?(clone_exists)
      stub_go_get(nil, success: go_get_success)
    end

    context 'when gitlab-elasticsaerch-indexer clone does not exist' do
      let(:clone_exists) { false }

      it 'returns true' do
        expect(subject).to be_success
      end
    end

    context 'when gitlab-elasticsaerch-indexer clone exists' do
      let(:clone_exists) { true }

      context 'but go get fails' do
        let(:go_get_success) { false }

        it 'returns false' do
          expect(subject).not_to be_success
        end
      end

      context 'and go get succeeds' do
        let(:go_get_success) { true }

        it 'returns true' do
          expect(subject).to be_success
        end
      end
    end
  end

  describe '#detail' do
    before do
      stub_go_get(nil, success: go_get_success)
    end

    context 'but go get fails' do
      let(:go_get_success) { false }

      it 'returns help message' do
        expect(subject.detail).to eq("Golang is current unable to build binaries that use the icu4c package.\nYou can try the following to fix:\n\ngo clean -cache\n")
      end
    end

    context 'and go get succeeds' do
      let(:go_get_success) { true }

      it 'returns nil' do
        expect(subject.detail).to be_nil
      end
    end
  end

  def stub_clone_exists?(exists)
    dir = Pathname.new('/home/git/gdk/gitlab-elasticsearch-indexer')
    settings = double('gitlab_elasticsearch_indexer settings', __dir: dir)
    allow_any_instance_of(GDK::Config).to receive(:gitlab_elasticsearch_indexer).and_return(settings)
    allow(dir).to receive(:exist?).and_return(exists)
  end

  def stub_go_get(result, success: true)
    shellout = double('Shellout', try_run: result, read_stdout: result, success?: success)
    allow(Shellout).to receive(:new).with(%w[go get], chdir: '/home/git/gdk/gitlab-elasticsearch-indexer').and_return(shellout)
    allow(shellout).to receive(:try_run).and_return(result)
  end
end
