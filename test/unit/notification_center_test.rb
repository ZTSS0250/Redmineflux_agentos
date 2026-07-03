# frozen_string_literal: true

require File.expand_path('../test_helper', __dir__)

# rao-021 (WORKFLOW.md §23). Exercises NotificationCenter's own
# recipient-resolution logic against lightweight doubles — same
# rationale as `test/unit/prompts/template_resolver_test.rb`'s
# `OpenStruct.new(id: 7)` standing in for an agent: what's under test
# here is the routing logic, not Redmine core's own association/
# persistence behavior. `FakeAgentRun` is a plain duck-typed double, not
# a real `RedminefluxAgentosAgentRun` — that model's `belongs_to
# :project`/`:issue` are real Rails associations that type-check their
# assigned object's class, so a fake `Project`/`Issue` double could never
# be assigned to them directly; NotificationCenter only ever calls
# `.project`/`.issue`/`.agent`/`.attempts`/`.max_attempts` on whatever is
# passed, so a plain Struct satisfies its actual contract. Doubles are
# nested under this test class so they never collide with the real
# global `Project`/`User`/`Issue` constants.
#
# `NotificationMailer.event_notification` is stubbed rather than
# exercised for real — actual mail delivery/rendering is Redmine's own
# already-proven ActionMailer pipeline, not something this ticket's
# routing logic needs to re-verify.
class NotificationCenterTest < ActiveSupport::TestCase
  FakeProject = Struct.new(:id, :name, :users)
  FakeUser = Struct.new(:id, :mail, :granted_permissions) do
    def allowed_to?(permission, _project)
      granted_permissions.include?(permission)
    end
  end
  FakeIssue = Struct.new(:id, :subject, :assigned_to, :watcher_users)
  FakeAgentRun = Struct.new(:id, :project, :issue, :agent, :attempts, :max_attempts)
  FakeMcpToolCallDouble = Struct.new(:agent_run, :tool_name)

  def setup
    RedminefluxAgentosConfiguration.clear!
    @deliveries = []
    RedminefluxAgentos::NotificationMailer.stubs(:event_notification).with do |user, subject, body|
      @deliveries << { user: user, subject: subject, body: body }
      true
    end.returns(stub(deliver_later: true))
  end

  def project_with_members(*users)
    FakeProject.new(101, 'Acme Website', users)
  end

  def build_agent_run(project:, issue: nil)
    agent = RedminefluxAgentosAgent.create!(key: "notif_test_#{object_id}_#{rand(1_000_000)}", name: 'Backend Agent',
                                             status: 'enabled')
    FakeAgentRun.new(9, project, issue, agent, 3, 3)
  end

  def test_agent_completed_notifies_assignee_and_watchers_deduped
    assignee = FakeUser.new(1, 'a@example.com', [])
    watcher = FakeUser.new(2, 'w@example.com', [])
    issue = FakeIssue.new(55, 'Build login page', assignee, [watcher])
    run = build_agent_run(project: project_with_members, issue: issue)

    RedminefluxAgentos::NotificationCenter.agent_completed(run)

    recipients = @deliveries.map { |d| d[:user] }
    assert_equal [assignee, watcher].sort_by(&:id), recipients.sort_by(&:id)
  end

  def test_agent_completed_does_nothing_without_an_issue
    run = build_agent_run(project: project_with_members, issue: nil)

    RedminefluxAgentos::NotificationCenter.agent_completed(run)

    assert_empty @deliveries
  end

  def test_agent_dead_notifies_only_users_with_view_agent_logs
    holder = FakeUser.new(3, 'h@example.com', [:view_agent_logs])
    non_holder = FakeUser.new(4, 'n@example.com', [])
    run = build_agent_run(project: project_with_members(holder, non_holder))

    RedminefluxAgentos::NotificationCenter.agent_dead(run)

    assert_equal [holder], @deliveries.map { |d| d[:user] }
  end

  def test_approval_needed_notifies_only_users_with_run_ai_tasks
    approver = FakeUser.new(5, 'ap@example.com', [:run_ai_tasks])
    run = build_agent_run(project: project_with_members(approver))
    call = FakeMcpToolCallDouble.new(run, 'delete_issue')

    RedminefluxAgentos::NotificationCenter.approval_needed(call)

    assert_equal [approver], @deliveries.map { |d| d[:user] }
  end

  def test_approval_needed_skips_when_call_has_no_agent_run
    call = FakeMcpToolCallDouble.new(nil, 'delete_issue')

    RedminefluxAgentos::NotificationCenter.approval_needed(call)

    assert_empty @deliveries
  end

  def test_agent_started_is_off_by_default
    member = FakeUser.new(6, 'm@example.com', [])
    run = build_agent_run(project: project_with_members(member))

    RedminefluxAgentos::NotificationCenter.agent_started(run)

    assert_empty @deliveries
  end

  def test_agent_started_notifies_project_members_when_enabled
    member = FakeUser.new(7, 'm2@example.com', [])
    project = project_with_members(member)
    run = build_agent_run(project: project)
    RedminefluxAgentosConfiguration.set!(project_id: project.id, key: 'notify_on_agent_started', value: true)

    RedminefluxAgentos::NotificationCenter.agent_started(run)

    assert_equal [member], @deliveries.map { |d| d[:user] }
  end

  def test_deliver_skips_recipients_with_no_mail_address
    mailless = FakeUser.new(8, nil, [])
    project = project_with_members(mailless)
    run = build_agent_run(project: project)
    RedminefluxAgentosConfiguration.set!(project_id: project.id, key: 'notify_on_agent_started', value: true)

    RedminefluxAgentos::NotificationCenter.agent_started(run)

    assert_empty @deliveries
  end
end
