# frozen_string_literal: true

module Openbox
  # :nodoc:
  module Commands
    # The Server Command
    #
    # @since 0.1.0
    class Server < Openbox::Command
      # Run Application Server
      #
      # @since 0.1.0
      def execute
        Openbox.database.ensure_connection!
        invoke Migrate unless ENV['AUTO_MIGRATION'].nil?
        exec("bundle exec #{thruster}#{server_command}")
      end

      private

      def thruster
        Openbox.runtime.has?('thruster') ? 'thrust ' : ''
      end

      def server_command
        return 'rails server -b 0.0.0.0' if Openbox.runtime.rails?

        'rackup -o 0.0.0.0'
      end
    end

    if Openbox.runtime.has?('rails', 'rack')
      Openbox::Entrypoint.register(Server, 'server', 'server', 'Start application server')
    end
  end
end
