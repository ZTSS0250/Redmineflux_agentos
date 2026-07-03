# frozen_string_literal: true

module RedminefluxAgentos
  module Agents
    # docs/AGENTS.md #3.
    class BusinessAnalystAgent < BaseAgent
      def self.key
        :business_analyst
      end

      def self.prompt_category
        'project_planning'
      end
    end
  end
end
