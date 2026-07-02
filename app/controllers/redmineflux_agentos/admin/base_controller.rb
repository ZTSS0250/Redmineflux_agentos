# frozen_string_literal: true

module RedminefluxAgentos
  module Admin
    # Shared base for every AgentOS administration controller — gated by
    # the admin-scope permissions declared in init.rb (require: :admin),
    # not by a project's module state.
    class BaseController < ApplicationController
      before_action :require_login
      before_action :authorize_global
      accept_api_auth
    end
  end
end
