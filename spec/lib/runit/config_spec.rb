require 'spec_helper'
require 'tempfile'

describe Runit::Config do
  let(:tmp_root) { File.expand_path('../../../tmp', __dir__) }
  let(:gdk_root) { Dir.mktmpdir(nil, tmp_root) }

  subject { described_class.new(gdk_root) }

  after { FileUtils.rm_rf(gdk_root) }

  describe '#stale_service_links' do
    let(:services) { [described_class::Service.new('svc1', nil), described_class::Service.new('svc2', nil)] }
    let(:services_dir) { File.join(gdk_root, 'services') }

    it 'removes unknown symlinks from the services directory' do
      FileUtils.mkdir_p(services_dir)

      %w[svc1 svc2 stale].each do |entry|
        File.symlink('/', File.join(services_dir, entry))
      end

      FileUtils.touch(File.join(services_dir, 'should-be-ignored'))

      expect(subject.stale_service_links(services)).to eq([File.join(services_dir, 'stale')])
    end
  end
end
