# frozen_string_literal: true

require 'spec_helper'

describe GDK::Diagnostic::Geo do
  let(:database_geo_yml_file) { '/home/git/gdk/gitlab/config/database_geo.yml' }

  describe '#diagnose' do
    context "when Geo database YAML file doesn't exist" do
      it 'sets @success to true' do
        stub_database_geo_yml_file(false)

        subject.diagnose

        expect(subject).to be_success
      end
    end

    context 'when Geo database YAML file does exist' do
      before do
        stub_database_geo_yml_file(true)
      end

      context 'and geo.enabled is set to false' do
        it 'sets @success to false' do
          stub_geo_enabled(false)

          subject.diagnose

          expect(subject).not_to be_success
        end
      end

      context 'and geo.enabled is set to true' do
        it 'sets @success to true' do
          stub_geo_enabled(true)

          subject.diagnose

          expect(subject).to be_success
        end
      end
    end
  end

  describe '#success?' do
    before do
      subject.instance_variable_set(:@success, success)
    end

    context 'when #diagnose has not yet be run' do
      let(:success) { nil }

      it { is_expected.not_to be_success }
    end

    context 'when #diagnose is unsuccessful' do
      let(:success) { false }

      it { is_expected.not_to be_success }
    end

    context 'when #diagnose is successful' do
      let(:success) { true }

      it { is_expected.to be_success }
    end
  end

  describe '#detail' do
    it 'returns a message advising how to detail with the situation' do
      expected_detail = <<~MESSAGE
        #{database_geo_yml_file} exists but
        geo.enabled is not set to true in your gdk.yml.

        Either update your gdk.yml to set geo.enabled to true or remove
        #{database_geo_yml_file}

        https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/howto/geo.md
      MESSAGE

      expect(subject.detail).to eq(expected_detail)
    end
  end

  def stub_database_geo_yml_file(exists)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(database_geo_yml_file).and_return(exists)
  end

  def stub_geo_enabled(enabled)
    gdk_geo_config = double('geo config', enabled: enabled)
    allow_any_instance_of(GDK::Config).to receive(:geo).and_return(gdk_geo_config)
  end
end
