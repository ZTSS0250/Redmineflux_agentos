// Live-polling dashboard updates (Agent/Dependency/Release/Token/Cost
// dashboards, docs/PHASE9-UI-UX-SPECIFICATION.md §6).
//
// No partial-refresh JSON endpoint exists for any dashboard yet (that
// would be new controller surface beyond this ticket's Code Changes
// table) — this is a deliberately simple full-page reload poll, opt-in
// per page via `<body data-agentos-poll-seconds="30">`, which is a
// legitimate "live" reading of the requirement without inventing an
// API this ticket doesn't own. A future ticket can replace this with a
// partial AJAX refresh without changing the opt-in mechanism.
document.addEventListener('DOMContentLoaded', function () {
  var seconds = parseInt(document.body.getAttribute('data-agentos-poll-seconds'), 10);
  if (!seconds || seconds <= 0) return;

  window.setTimeout(function () {
    window.location.reload();
  }, seconds * 1000);
});
