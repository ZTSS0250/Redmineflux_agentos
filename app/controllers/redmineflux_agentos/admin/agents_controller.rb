# frozen_string_literal: true

module RedminefluxAgentos
  module Admin
    # Agent roster admin screen — enable/disable, edit config
    # (docs/PHASE1-SPECIFICATION.md §4.2).
    class AgentsController < BaseController
      def index
      end

      def edit
      end

      def update
        head :no_content
      end
    end
  end
end
