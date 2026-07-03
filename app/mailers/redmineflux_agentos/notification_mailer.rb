# frozen_string_literal: true

module RedminefluxAgentos
  # The actual send step behind NotificationCenter (WORKFLOW.md §23) —
  # "Redmine's native notification system" is, at its core, email
  # delivery through the same ActionMailer pipeline Redmine's own
  # `Mailer` class uses. A dedicated plugin mailer with a body passed
  # directly to `mail(...)` (no view template) is used instead of
  # reaching into Redmine core's own `Mailer` — this ticket doesn't own
  # deciding email template wording/layout for AgentOS's notification
  # content (no design doc specifies it), so it deliberately keeps the
  # message plain-text and minimal rather than inventing a look.
  class NotificationMailer < ActionMailer::Base
    default from: -> { Setting.mail_from }

    def event_notification(user, subject_line, body_text)
      mail(to: user.mail, subject: subject_line, body: body_text, content_type: 'text/plain')
    end
  end
end
