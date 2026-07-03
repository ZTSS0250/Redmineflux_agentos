// Pending Approvals queue interactions on the Agent Dashboard
// (docs/UI-WIREFRAMES.md §3, WORKFLOW.md §22).
//
// The actual approve/reject network round trip and row removal are
// handled server-side via Rails UJS (`remote: true` on each button in
// agent_dashboards/index.html.erb) plus the approve.js.erb/reject.js.erb
// response templates — this file only adds the one client-only
// behavior those templates can't: a confirmation prompt before a
// destructive-adjacent reject action, matching Redmine's own
// `data-confirm` convention used everywhere else in core.
document.addEventListener('DOMContentLoaded', function () {
  document.querySelectorAll('#agentos-pending-approvals .icon-del').forEach(function (button) {
    button.addEventListener('click', function (event) {
      if (!window.confirm('Reject this tool call? This cannot be undone.')) {
        event.preventDefault();
        event.stopImmediatePropagation();
      }
    });
  });
});
