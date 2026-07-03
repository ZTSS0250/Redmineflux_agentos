# frozen_string_literal: true

module RedminefluxAgentos
  module Mcp
    module Tools
      # create_project, update_project, read_project, create_version
      # (docs/MCP-TOOLS.md "Project & planning"). None require
      # confirmation. Permission mapping (Layer 1) — not spelled out by
      # any doc, an interpretive decision logged in rao-018 — uses the
      # nearest stock Redmine permission for each action: `:add_project`
      # is global (no project exists yet when creating one); the rest are
      # project-scoped.
      module ProjectTools
        # `extend`, not `include` — every method here is a `module_function`
        # (called directly on the module, e.g. `ProjectTools.create_project`),
        # so Support's helpers must be mixed into ProjectTools's singleton
        # class to be callable bare from within them; `include` would only
        # reach instances of a class that includes ProjectTools, which
        # never happens here.
        extend Support

        module_function

        def register!
          Mcp::ToolRegistry.register(
            :redmineflux_agentos_create_project,
            category: 'project_planning',
            handler: method(:create_project),
            params_schema: {
              name: { type: String, required: true },
              identifier: { type: String, required: true },
              description: { type: String, required: false },
              modules: { type: Array, required: false }
            },
            authorize: ->(actor, _params) { actor.allowed_to?(:add_project, nil, global: true) }
          )

          Mcp::ToolRegistry.register(
            :redmineflux_agentos_update_project,
            category: 'project_planning',
            handler: method(:update_project),
            params_schema: {
              project_id: { required: true },
              name: { type: String, required: false },
              description: { type: String, required: false }
            },
            authorize: ->(actor, params) { (project = find_project(params)) && actor.allowed_to?(:edit_project, project) }
          )

          Mcp::ToolRegistry.register(
            :redmineflux_agentos_read_project,
            category: 'project_planning',
            handler: method(:read_project),
            params_schema: { project_id: { required: true } },
            authorize: ->(actor, params) { (project = find_project(params)) && project.visible?(actor) },
            read_only: true
          )

          Mcp::ToolRegistry.register(
            :redmineflux_agentos_create_version,
            category: 'release_planning',
            handler: method(:create_version),
            params_schema: {
              project_id: { required: true },
              name: { type: String, required: true },
              description: { type: String, required: false },
              due_date: { type: String, required: false }
            },
            authorize: ->(actor, params) { (project = find_project(params)) && actor.allowed_to?(:manage_versions, project) }
          )
        end

        def create_project(params, _actor)
          project = Project.new(
            name: param(params, :name),
            identifier: param(params, :identifier),
            description: param(params, :description)
          )
          project.save!

          modules = Array(param(params, :modules))
          project.enabled_module_names |= modules if modules.any?

          {
            result: { id: project.id, identifier: project.identifier, name: project.name },
            action: 'project.created',
            target_type: 'Project',
            target_id: project.id,
            before: nil,
            after: { name: project.name, identifier: project.identifier }
          }
        end

        def update_project(params, _actor)
          project = find_project(params)
          raise ActiveRecord::RecordNotFound, "No project matching #{param(params, :project_id)}" unless project

          before = project.attributes.slice('name', 'description')
          project.name = param(params, :name) if param(params, :name)
          project.description = param(params, :description) if param(params, :description)
          project.save!

          {
            result: { id: project.id, identifier: project.identifier, name: project.name },
            action: 'project.updated',
            target_type: 'Project',
            target_id: project.id,
            before: before,
            after: project.attributes.slice('name', 'description')
          }
        end

        def read_project(params, _actor)
          project = find_project(params)
          raise ActiveRecord::RecordNotFound, "No project matching #{param(params, :project_id)}" unless project

          { result: { id: project.id, identifier: project.identifier, name: project.name,
                      description: project.description, status: project.status } }
        end

        def create_version(params, _actor)
          project = find_project(params)
          raise ActiveRecord::RecordNotFound, "No project matching #{param(params, :project_id)}" unless project

          version = Version.new(
            project: project,
            name: param(params, :name),
            description: param(params, :description),
            effective_date: param(params, :due_date)
          )
          version.save!

          {
            result: { id: version.id, name: version.name },
            action: 'version.created',
            target_type: 'Version',
            target_id: version.id,
            before: nil,
            after: { name: version.name }
          }
        end
      end
    end
  end
end
