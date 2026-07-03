# frozen_string_literal: true

module RedminefluxAgentos
  module Configuration
    # Reads `redmineflux_agentos_configurations`
    # (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §B.6): a project-scoped
    # row overrides a global-default row (`project_id: nil`) for the same
    # `key`; callers never manually check both rows.
    #
    # Scope note: only the read path (`get`) is implemented here, as much
    # as Phase 12 (rao-017) needs to resolve `active_provider` — the write
    # path and the explicit-invalidation cache §B.6 also calls for belong
    # to whichever future phase's Settings admin page (Phase 15, rao-020)
    # first needs to *write* a configuration value. `get` always reads
    # through to the database; there is no cache yet.
    module Store
      # v1 defaults per docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §12 —
      # used only when no `redmineflux_agentos_configurations` row exists
      # for a key yet (e.g. a fresh install before any admin has visited
      # the Settings page).
      DEFAULTS = {
        'active_provider' => 'mock',
        'fixture_directory' => 'config/agentos/fixtures/mock_provider',
        'logging_level' => (Rails.env.production? ? 'info' : 'debug'),
        'prompt_version_pinning' => nil,
        'simulation_mode' => 'deterministic',
        'cost_rules' => 'mock-standard',
        'token_rules' => 'fixture_declared'
      }.freeze

      class << self
        # @param key [String, Symbol]
        # @param project [Project, nil]
        # @return the resolved value — project override, else global
        #   default row, else the v1 DEFAULTS constant, else nil
        def get(key, project: nil)
          key = key.to_s

          if project
            scoped = RedminefluxAgentosConfiguration.find_by(project_id: project.id, key: key)
            return parse(scoped.value_json) if scoped
          end

          global = RedminefluxAgentosConfiguration.find_by(project_id: nil, key: key)
          return parse(global.value_json) if global

          DEFAULTS[key]
        end

        private

        def parse(value_json)
          return nil if value_json.nil?

          JSON.parse(value_json)
        rescue JSON::ParserError
          # A hand-edited or legacy row that isn't valid JSON — treat the
          # raw stored string as the value rather than raising, since a
          # config-read must never be the reason an agent run fails.
          value_json
        end
      end
    end
  end
end
