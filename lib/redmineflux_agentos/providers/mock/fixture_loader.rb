# frozen_string_literal: true

module RedminefluxAgentos
  module Providers
    module Mock
      # Reads a fixture YAML file from the configured `fixture_directory`
      # (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md §12). Validates the
      # directory exists at boot and logs a clear warning if missing,
      # rather than only failing per-request (rao-008 Gate 3 finding #1).
      module FixtureLoader
        # The generic "unhandled scenario" fixture FixtureSelector falls
        # back to when a specific scenario has no fixture of its own (§8.5).
        FALLBACK_RELATIVE_PATH = '_fallback/unhandled_scenario.yml'

        class << self
          # Absolute path to the configured fixture directory, resolved
          # against this plugin's own root (not the main Rails app's root —
          # a Redmine plugin's fixtures ship inside the plugin itself).
          def root
            plugin_directory = Redmine::Plugin.find(:redmineflux_agentos).directory
            File.join(plugin_directory, RedminefluxAgentos::Configuration::Store.get('fixture_directory'))
          end

          # Called once at boot (config/initializers/redmineflux_agentos.rb)
          # so a misconfigured fixture_directory is a loud, one-time
          # boot-time warning — never a silent per-request failure
          # (rao-008 Gate 3 finding #1, rao-017 Test Case #4).
          def validate_directory!
            return true if Dir.exist?(root)

            Rails.logger.warn(
              "[RedminefluxAgentos] Mock Provider fixture_directory does not exist: #{root} — " \
              'every Mock Provider request will fail with Providers::FixtureNotFoundError until this is fixed.'
            )
            false
          end

          # @param relative_path [String] e.g.
          #   "project_manager/project_planning/create_project.yml"
          # @return [Hash, nil] the parsed fixture, or nil if the file
          #   doesn't exist (the caller — FixtureSelector — decides whether
          #   that means "fall back" or "raise")
          def load(relative_path)
            full_path = File.join(root, relative_path)
            return nil unless File.exist?(full_path)

            YAML.safe_load(File.read(full_path), permitted_classes: [], aliases: true) || {}
          end
        end
      end
    end
  end
end
