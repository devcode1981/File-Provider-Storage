# frozen_string_literal: true

require 'spec_helper'

describe GDK::ErbRenderer do
  let(:overwrite_changes) { true }
  let(:erb_file) { fixture_path.join('example.erb') }
  let(:out_file) { temp_path.join('example.out') }

  subject(:renderer) { described_class.new(erb_file.to_s, out_file.to_s, config: config) }

  let(:config) { config_klass.new(yaml: { 'gdk' => { 'overwrite_changes' => overwrite_changes } }) }

  let(:config_klass) do
    Class.new(GDK::ConfigSettings) do
      foo 'foo'
      bar 'bar'

      gdk { |g| g.overwrite_changes true }
    end
  end

  before do
    allow(renderer).to receive(:wait!)
    allow(renderer).to receive(:backup!)
  end

  after(:each) do
    out_file.unlink
  end

  describe '#safe_render!' do
    context 'output file does not exist' do
      it 'renders without a warning' do
        expect(renderer).not_to receive(:warn_changes!)

        renderer.safe_render!

        expect(File.read(out_file)).to match('Foo is foo, and Bar is bar')
      end
    end

    context 'output file exists with differences' do
      before do
        File.write(out_file, 'Foo is bar')
      end

      context 'overwrite set to true' do
        let(:overwrite_changes) { true }

        it 'warns about changes and overwrites content' do
          expect(renderer).to receive(:warn_changes!)

          renderer.safe_render!

          expect(File.read(out_file)).to match('Foo is foo, and Bar is bar')
        end
      end

      context 'overwrite set to false' do
        let(:overwrite_changes) { false }

        it 'warns about changes and does not overwrite content' do
          expect(renderer).to receive(:warn_changes!)

          renderer.safe_render!

          expect(File.read(out_file)).to match('Foo is bar')
        end
      end
    end
  end
end
