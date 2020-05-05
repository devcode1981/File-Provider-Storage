# frozen_string_literal: true

require_relative 'services/base'

module GDK
  # Services module contains individual service classes (e.g. Redis) that
  # are responsible for producing the correct command line to execute and
  # if the service should in fact be executed.
  #
  module Services
    # Returns an Array of all services, including enabled and not
    # enabled.
    #
    # @return [Array<Class>] all services
    def self.all
      klasses = []

      klasses.map do |const|
        const_get(const).new
      end
    end
  end
end
