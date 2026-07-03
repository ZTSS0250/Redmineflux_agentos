# frozen_string_literal: true

module RedminefluxAgentos
  module Mcp
    module Tools
      # Shared helpers for every tool handler file (project/issue/wiki/
      # file/time/reporting_tools.rb) — not itemized as its own file in
      # rao-018's Code Changes table, but every handler needs the same
      # string/symbol-agnostic param access and Project/Issue lookups, so
      # duplicating this six times would violate the Gate 1 finding that
      # all six tool files "must share the same handler shape."
      module Support
        module_function

        # Params arrive as either string or symbol keys depending on
        # caller (a controller's `params` vs. a Ruby hash built by an
        # agent) — every handler reads through this instead of assuming one.
        def param(params, key)
          params[key.to_sym] || params[key.to_s]
        end

        # @return [Project, nil] — nil (not an exception) so a tool's own
        #   `authorize:` proc can treat "no such project" as simply denied
        #   rather than needing its own rescue
        def find_project(params)
          project_id = param(params, :project_id)
          return nil if project_id.blank?

          Project.find_by(id: project_id) || Project.find_by(identifier: project_id)
        end

        # @return [Issue, nil]
        def find_issue(params)
          issue_id = param(params, :issue_id)
          return nil if issue_id.blank?

          Issue.find_by(id: issue_id)
        end
      end
    end
  end
end
