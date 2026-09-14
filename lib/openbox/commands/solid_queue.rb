# frozen_string_literal: true

module Openbox
  # :nodoc:
  module Commands
    # The SolidQueue Command
    #
    # @since 0.1.0
    class SolidQueue < Openbox::Command
      # Run solid_queue worker
      #
      # @since 0.1.0
      def execute
        Openbox.database.ensure_connection!
        exec('bundle exec rake solid_queue:start')
      end
    end

    if Openbox.runtime.has?('solid_queue')
      Openbox::Entrypoint.register(SolidQueue, 'solid_queue', 'solid_queue', 'Run solid_queue worker')
    end
  end
end
