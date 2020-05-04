# frozen_string_literal: true

require 'spec_helper'

describe GDK::Diagnostic do
  describe '.all' do
    it 'creates instances of all GDK::Diagnostic classes' do
      expect { described_class.all }.not_to raise_error
    end

    it 'contains only diagnostic classes' do
      diagnostic_classes = [
        GDK::Diagnostic::RubyGems,
        GDK::Diagnostic::Version,
        GDK::Diagnostic::Configuration,
        GDK::Diagnostic::Git,
        GDK::Diagnostic::Dependencies,
        GDK::Diagnostic::PendingMigrations,
        GDK::Diagnostic::Geo,
        GDK::Diagnostic::Status,
        GDK::Diagnostic::Re2
      ]

      expect(described_class.all.map(&:class)).to eq(diagnostic_classes)
    end
  end
end
