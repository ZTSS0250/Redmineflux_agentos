# frozen_string_literal: true

module RedminefluxAgentos
  module Services
    # The canonical service-object shape every service in this plugin
    # follows (docs/PHASE2-CORE-TECHNICAL-ARCHITECTURE.md §A.2): one
    # public entry point (`.call`), a Result object rather than exceptions
    # for expected failures, constructor-injected dependencies, and the
    # service owns its own transaction if it writes more than one table.
    class BaseService
      Result = Struct.new(:success?, :value, :errors, keyword_init: true) do
        def self.success(value = nil)
          new(success?: true, value: value, errors: [])
        end

        def self.failure(errors)
          new(success?: false, value: nil, errors: Array(errors))
        end
      end

      def self.call(...)
        new(...).call
      end

      def call
        raise NotImplementedError, "#{self.class.name}#call must be implemented"
      end
    end
  end
end
