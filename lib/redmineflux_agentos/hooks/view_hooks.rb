# frozen_string_literal: true

module RedminefluxAgentos
  module Hooks
    # Redmine::Hook listener reserved for future view injection points
    # (e.g. surfacing an AgentOS summary widget on the native Project
    # Overview page). No hooks are registered yet — this is a skeleton
    # namespace only; injection points are added alongside the UI
    # implementation task that needs them (Phase 15, rao-020), not here.
    class ViewHooks < Redmine::Hook::ViewListener
    end
  end
end
