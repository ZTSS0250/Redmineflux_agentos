# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #10. Tier 4 in the default dependency chain (parallel with Frontend Agent).
    class UiUxAgent < BaseAgent
      def self.key
        :ui_ux
      end
    end
  end
end
