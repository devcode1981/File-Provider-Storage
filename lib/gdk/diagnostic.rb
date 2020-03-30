# frozen_string_literal: true


require_relative 'diagnostic/base'
require_relative 'diagnostic/dependencies'
require_relative 'diagnostic/version'
require_relative 'diagnostic/status'
require_relative 'diagnostic/pending_migrations'
require_relative 'diagnostic/configuration'
require_relative 'diagnostic/geo'

module GDK
  module Diagnostic
    def self.all
      klasses = constants - [:Base]

      klasses.map do |const|
        const_get(const).new
      end
    end
  end
end
