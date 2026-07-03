# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #1.
    class ProjectManagerAgent < BaseAgent
      def self.key
        :project_manager
      end

      def self.prompt_category
        'project_planning'
      end
    end
  end
end
