# frozen_string_literal: true

require_relative 'diagnostic/base'
require_relative 'diagnostic/dependencies'
require_relative 'diagnostic/version'
require_relative 'diagnostic/status'
require_relative 'diagnostic/pending_migrations'
require_relative 'diagnostic/configuration'
require_relative 'diagnostic/geo'
require_relative 'diagnostic/git'
require_relative 'diagnostic/ruby_gems'
require_relative 'diagnostic/re2'
require_relative 'diagnostic/golang'

module GDK
  module Diagnostic
    def self.all
      klasses = %i[
        RubyGems
        Version
        Configuration
        Git
        Dependencies
        PendingMigrations
        Geo
        Status
        Re2
        Golang
      ]

      klasses.map do |const|
        const_get(const).new
      end
    end
  end
end
