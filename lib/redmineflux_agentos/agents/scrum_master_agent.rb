# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #4.
    class ScrumMasterAgent < BaseAgent
      def self.key
        :scrum_master
      end
    end
  end
end
