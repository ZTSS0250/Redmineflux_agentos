# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #1.
    class ProjectManagerAgent < BaseAgent
      def self.key
        :project_manager
      end
    end
  end
end
