# frozen_string_literal: true

module RedminefluxAgentos
  module Providers
    module Mock
      # Fake Ticket Generation (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md
      # §7.2) — a deterministic generation ALGORITHM, not a hand-authored
      # fixture, since the combinatorics of epics x stories x tasks would
      # be impractical to hand-author for every possible SRS. Invoked by
      # MockProvider when a fixture declares `generation_rule:
      # ticket_generation` (the "Ticket Creation" scenario, §7).
      #
      # Round-robin story points are derived from each story's own index
      # within this single call, never from shared/global state — the same
      # epic input always produces the same point distribution, and two
      # concurrent calls never interfere with each other (rao-017
      # Implementation Notes, rao-008 Gate 3 finding #2's determinism
      # requirement).
      module TicketGenerationRule
        POINT_SEQUENCE = [1, 2, 3, 5, 8].freeze
        DEFAULT_STORY_COUNT = 3
        TASKS_PER_STORY = 2

        class << self
          # @param epic [Hash] must include "title"; may include "module"
          #   (used for the deterministic label rule) and "story_count"
          #   (overrides DEFAULT_STORY_COUNT)
          # @return [Array<Hash>] deterministic story descriptors, each
          #   carrying its own nested "tasks" array
          def generate(epic)
            epic = epic.transform_keys(&:to_s)
            title = epic['title'].to_s
            label = epic['module']
            story_count = (epic['story_count'] || DEFAULT_STORY_COUNT).to_i

            Array.new(story_count) { |i| build_story(title, label, i) }
          end

          private

          def build_story(epic_title, label, index)
            story_title = "#{epic_title} — Story #{index + 1}"
            {
              'title' => story_title,
              'task_type' => 'story',
              'story_points' => POINT_SEQUENCE[index % POINT_SEQUENCE.length],
              'labels' => label,
              'acceptance_criteria' => acceptance_criteria(story_title),
              'tasks' => Array.new(TASKS_PER_STORY) { |j| build_task(story_title, label, index, j) }
            }
          end

          def build_task(story_title, label, story_index, task_index)
            point_index = story_index + task_index + 1
            {
              'title' => "#{story_title} — Task #{task_index + 1}",
              'task_type' => 'task',
              'story_points' => POINT_SEQUENCE[point_index % POINT_SEQUENCE.length],
              'labels' => label
            }
          end

          def acceptance_criteria(story_title)
            "Given a user needs \"#{story_title}\", " \
              'When the feature is implemented, ' \
              "Then it satisfies the story's acceptance criteria as verified by QA."
          end
        end
      end
    end
  end
end
