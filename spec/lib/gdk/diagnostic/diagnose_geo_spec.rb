# frozen_string_literal: true

require 'spec_helper'

describe GDK::Diagnostic::DiagnoseGeo do
  let(:gdk_config) { double('GDK::Config', gdk_root: Pathname.new('/tmp/non-existent-dir')) }
  let(:non_existent_database_geo_yml_file) { '/tmp/non-existent-dir/gitlab/config/database_geo.yml' }

  before do
    allow(GDK::Config).to receive(:new).and_return(gdk_config)
  end

  describe '#diagnose' do
    context "when Geo YML file doesn't exist" do
      it 'sets @success to true' do
        subject.diagnose

        expect(subject.success?).to be_truthy
      end
    end

    context 'when Geo YML file does exist' do
      let(:geo_enabled) { nil }

      before do
        gdk_geo_config = double('geo config', enabled: geo_enabled)

        allow(gdk_config).to receive(:geo).and_return(gdk_geo_config)
        allow(File).to receive(:exist?).with(non_existent_database_geo_yml_file).and_return(true)
      end

      context 'and geo.enabled is set to false' do
        let(:geo_enabled) { false }

        it 'sets @success to false' do
          subject.diagnose

          expect(subject.success?).to be_falsey
        end
      end

      context 'and geo.enabled is set to true' do
        let(:geo_enabled) { true }

        it 'sets @success to true' do
          subject.diagnose

          expect(subject.success?).to be_truthy
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

      it { is_expected.to_not be_success }
    end

    context 'when #diagnose is unsuccessful' do
      let(:success) { false }

      it { is_expected.to_not be_success }
    end

    context 'when #diagnose is successful' do
      let(:success) { true }

      it { is_expected.to be_success }
    end
  end

  describe '#detail' do
    it 'returns a message advising how to detail with the situation' do
      expected_detail = <<~MESSAGE
        #{non_existent_database_geo_yml_file} exists but
        geo.enabled is not set to true in your gdk.yml.

        Either update your gdk.yml to set geo.enabled to true or remove
        #{non_existent_database_geo_yml_file}

        https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/howto/geo.md
      MESSAGE

      expect(subject.detail).to eq(expected_detail)
    end
  end
end
