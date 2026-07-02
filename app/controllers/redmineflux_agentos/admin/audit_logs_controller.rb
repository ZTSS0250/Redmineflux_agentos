# frozen_string_literal: true

module RedminefluxAgentos
  module Admin
    # Audit Logs admin screen (docs/PHASE1-SPECIFICATION.md §4.2).
    # Read-only — RedminefluxAgentosAuditLog itself enforces immutability
    # at the model layer (docs/PHASE4-DATABASE-DESIGN.md §9).
    class AuditLogsController < BaseController
      def index
      end

      def show
      end
    end
  end
end
