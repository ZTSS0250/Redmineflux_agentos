# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #17. Continuous (not tiered) — schedule/request-triggered.
    class ReportingAgent < BaseAgent
      def self.key
        :reporting
      end
    end
  end
end
