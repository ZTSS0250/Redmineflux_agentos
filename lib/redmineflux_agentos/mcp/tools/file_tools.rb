# frozen_string_literal: true

module RedminefluxAgentos
  module Mcp
    module Tools
      # upload_file (docs/MCP-TOOLS.md "Files").
      #
      # Scoping decision: `docs/MCP-TOOLS.md` says this attaches "a file
      # to an issue/wiki/project" — three different container types with
      # three different natural Redmine permissions. `container_type`
      # is restricted to exactly those three; anything else is an
      # InvalidParamsError from the params_schema `type:` mismatch (an
      # unrecognized string just fails the container-lookup step instead).
      # Live-verification flag: Redmine's `Attachment` model's exact
      # expected `file=` interface (an object responding to
      # `original_filename`/`content_type`/`read`) is matched here from
      # Redmine core knowledge, not copied from an existing call site in
      # this codebase (the sibling `redmineflux_devops` plugin never
      # creates Attachments) — worth a first live-instance check.
      module FileTools
        extend Support

        CONTAINER_PERMISSIONS = {
          'Issue' => :edit_issues,
          'WikiPage' => :edit_wiki_pages,
          'Project' => :manage_files
        }.freeze

        module_function

        def register!
          Mcp::ToolRegistry.register(
            :redmineflux_agentos_upload_file,
            category: 'documentation',
            handler: method(:upload_file),
            params_schema: {
              container_type: { type: String, required: true },
              container_id: { required: true },
              filename: { type: String, required: true },
              content: { type: String, required: true },
              content_type: { type: String, required: false }
            },
            authorize: ->(actor, params) { upload_authorized?(actor, params) }
          )
        end

        def upload_authorized?(actor, params)
          container = find_container(params)
          return false unless container

          permission = CONTAINER_PERMISSIONS[param(params, :container_type)]
          return false unless permission

          project = container.is_a?(Project) ? container : container.project
          actor.allowed_to?(permission, project)
        end

        def find_container(params)
          type = param(params, :container_type)
          id = param(params, :container_id)
          return nil unless %w[Issue WikiPage Project].include?(type) && id.present?

          type.constantize.find_by(id: id)
        end

        def upload_file(params, actor)
          container = find_container(params)
          raise ActiveRecord::RecordNotFound, "No #{param(params, :container_type)} matching #{param(params, :container_id)}" unless container

          io = StringIO.new(param(params, :content).to_s)
          filename = param(params, :filename)
          content_type = param(params, :content_type) || 'application/octet-stream'
          io.define_singleton_method(:original_filename) { filename }
          io.define_singleton_method(:content_type) { content_type }

          attachment = Attachment.new(file: io, author: actor)
          attachment.container = container
          attachment.save!

          {
            result: { id: attachment.id, filename: attachment.filename },
            action: 'attachment.created',
            target_type: 'Attachment',
            target_id: attachment.id,
            before: nil,
            after: { filename: attachment.filename, container_type: container.class.name, container_id: container.id }
          }
        end
      end
    end
  end
end
