# frozen_string_literal: true

require 'spec_helper'

describe GDK do
  before do
    allow(GDK).to receive(:install_root_ok?).and_return(true)
  end

  def expect_exec(input, cmdline)
    expect(subject).to receive(:exec).with(*cmdline)

    ARGV.replace(input)
    subject.main
  end

  describe '.main' do
    describe 'psql' do
      it 'uses the development database by default' do
        expect_exec ['psql'],
          ['psql', '-h', GDK.root.join('postgresql').to_s, '-p', '5432', '-d', 'gitlabhq_development', chdir: GDK.root]
      end

      it 'uses custom arguments if present' do
        expect_exec ['psql', '-w', '-d', 'gitlabhq_test'],
          ['psql', '-h', GDK.root.join('postgresql').to_s, '-p', '5432', '-w', '-d', 'gitlabhq_test', chdir: GDK.root]
      end
    end
  end
end
