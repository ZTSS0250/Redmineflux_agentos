# frozen_string_literal: true

module RedminefluxAgentos
  module Mcp
    module Tools
      # create_wiki_page, update_wiki, search_wiki (docs/MCP-TOOLS.md
      # "Wiki"). None require confirmation.
      module WikiTools
        extend Support

        module_function

        def register!
          Mcp::ToolRegistry.register(
            :redmineflux_agentos_create_wiki_page,
            category: 'documentation',
            handler: method(:create_wiki_page),
            params_schema: {
              project_id: { required: true },
              title: { type: String, required: true },
              text: { type: String, required: true }
            },
            authorize: ->(actor, params) { (project = find_project(params)) && actor.allowed_to?(:edit_wiki_pages, project) }
          )

          Mcp::ToolRegistry.register(
            :redmineflux_agentos_update_wiki,
            category: 'documentation',
            handler: method(:update_wiki),
            params_schema: {
              project_id: { required: true },
              title: { type: String, required: true },
              text: { type: String, required: true },
              comments: { type: String, required: false }
            },
            authorize: ->(actor, params) { (project = find_project(params)) && actor.allowed_to?(:edit_wiki_pages, project) }
          )

          Mcp::ToolRegistry.register(
            :redmineflux_agentos_search_wiki,
            category: 'documentation',
            handler: method(:search_wiki),
            params_schema: { project_id: { required: true }, query: { type: String, required: true } },
            authorize: ->(actor, params) { (project = find_project(params)) && project.visible?(actor) },
            read_only: true
          )
        end

        def create_wiki_page(params, actor)
          project = find_project(params)
          raise ActiveRecord::RecordNotFound, "No project matching #{param(params, :project_id)}" unless project

          wiki = project.wiki || Wiki.create_default(project)
          page = WikiPage.new(wiki: wiki, title: param(params, :title))
          content = WikiContent.new(page: page)
          content.author = actor
          content.text = param(params, :text)
          raise ActiveRecord::RecordInvalid, page unless page.save_with_content(content)

          {
            result: { id: page.id, title: page.title },
            action: 'wiki_page.created',
            target_type: 'WikiPage',
            target_id: page.id,
            before: nil,
            after: { title: page.title }
          }
        end

        def update_wiki(params, actor)
          project = find_project(params)
          raise ActiveRecord::RecordNotFound, "No project matching #{param(params, :project_id)}" unless project

          wiki = project.wiki
          raise ActiveRecord::RecordNotFound, "Project #{project.id} has no wiki" unless wiki

          page = wiki.find_page(param(params, :title))
          raise ActiveRecord::RecordNotFound, "No wiki page titled #{param(params, :title)}" unless page

          before_text = page.content&.text
          content = page.content || WikiContent.new(page: page)
          content.author = actor
          content.text = param(params, :text)
          content.comments = param(params, :comments)
          raise ActiveRecord::RecordInvalid, page unless page.save_with_content(content)

          {
            result: { id: page.id, title: page.title, version: page.content.version },
            action: 'wiki_page.updated',
            target_type: 'WikiPage',
            target_id: page.id,
            before: { text: before_text },
            after: { text: content.text }
          }
        end

        def search_wiki(params, _actor)
          project = find_project(params)
          raise ActiveRecord::RecordNotFound, "No project matching #{param(params, :project_id)}" unless project

          query = param(params, :query)
          pages = project.wiki ? project.wiki.pages.joins(:content).where(
            'wiki_contents.text LIKE :q OR wiki_pages.title LIKE :q', q: "%#{query}%"
          ) : []

          { result: { pages: pages.map { |p| { id: p.id, title: p.title } } } }
        end
      end
    end
  end
end
