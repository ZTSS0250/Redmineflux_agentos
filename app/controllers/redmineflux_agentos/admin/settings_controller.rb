# frozen_string_literal: true

module RedminefluxAgentos
  module Admin
    # Settings / Configuration admin screen (docs/PHASE9-UI-UX-SPECIFICATION.md
    # §4.2). Reads/writes RedminefluxAgentosConfiguration exclusively — never
    # Redmine's built-in plugin settings mechanism (init.rb, rao-015 Gate 1
    # finding #3). Phase 15 implementation must never render a real
    # decrypted credential value here — masked indicator only (rao-014
    # Gate 2 finding #1).
    class SettingsController < BaseController
      def show
      end

      def update
        head :no_content
      end
    end
  end
end
