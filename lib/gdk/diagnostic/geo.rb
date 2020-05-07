# frozen_string_literal: true

module GDK
  module Diagnostic
    class Geo < Base
      TITLE = 'Geo'

      def diagnose
        @success = true

        @success = false if database_geo_yml_exists? && !geo_enabled?
      end

      def success?
        @success
      end

      def detail
        <<~MESSAGE
          #{database_geo_yml_file} exists but
          geo.enabled is not set to true in your gdk.yml.

          Either update your gdk.yml to set geo.enabled to true or remove
          #{database_geo_yml_file}

          #{geo_howto_url}
        MESSAGE
      end

      private

      def geo_enabled?
        config.geo.enabled
      end

      def database_geo_yml_file
        @database_geo_yml_file ||= config.gitlab.dir.join('config', 'database_geo.yml').expand_path.to_s
      end

      def database_geo_yml_exists?
        File.exist?(database_geo_yml_file)
      end

      def geo_howto_url
        'https://gitlab.com/gitlab-org/gitlab-development-kit/blob/master/doc/howto/geo.md'
      end
    end
  end
end
