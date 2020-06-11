# frozen_string_literal: true

require 'spec_helper'

describe GDK::Output do
  describe '.puts' do
    it 'puts to stdout' do
      expect { described_class.puts('test') }.to output("test\n").to_stdout
    end
  end

  describe '.color' do
    it 'returns a color for index' do
      expect(described_class.color(0)).to eq("31")
    end
  end

  describe '.ansi' do
    it 'returns and ansi encode string' do
      expect(described_class.ansi('31')).to eq("\e[31m")
    end
  end

  describe '.reset_color' do
    it 'returns and ansi encode string' do
      expect(described_class.reset_color).to eq("\e[0m")
    end
  end
end
