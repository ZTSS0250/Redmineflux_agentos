# frozen_string_literal: true

namespace :redmineflux_agentos do
  desc 'Provision the AgentOS System user and role (rao-015) — safe to run repeatedly'
  task provision_system_user: :environment do
    user = RedminefluxAgentos::SystemUserProvisioner.user
    puts "AgentOS System user ready: #{user.login} (id: #{user.id})"
  end

  desc 'Ensure the AgentOS System user is a member of every project with the :agentos module enabled'
  task sync_system_user_memberships: :environment do
    EnabledModule.where(name: 'agentos').find_each do |mod|
      RedminefluxAgentos::SystemUserProvisioner.ensure_membership!(mod.project)
    end
    puts 'AgentOS System user membership synced.'
  end
end
