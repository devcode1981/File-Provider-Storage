# frozen_string_literal: true

require_relative '../lib/gdk'

RSpec.configure do |config|
  config.before do
    allow($stdout).to receive(:puts)
    allow($stdout).to receive(:write)

    # isolate configs for the testing environment
    allow(GDK).to receive(:root) { Pathname.new(temp_path) }
    stub_const('GDK::Config::GDK_ROOT', '/home/git/gdk')
    stub_const('GDK::Config::FILE', 'gdk.example.yml')
  end
end

def spec_path
  Pathname.new(__dir__).expand_path
end

def fixture_path
  spec_path.join('fixtures')
end

def temp_path
  spec_path.parent.join('tmp')
end
