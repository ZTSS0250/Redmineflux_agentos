// AI Chat / New AI Project Wizard client behavior (docs/UI-WIREFRAMES.md §1).
//
// ChatController#create responds 204 No Content (chat_controller.rb) —
// there is no agent turn to render yet (see that controller's own
// documented gap comment), so this handler only clears the composer on
// a successful submit; it does not append a reply, since none exists.
document.addEventListener('DOMContentLoaded', function () {
  var messages = document.querySelector('#agentos-chat-messages');
  var form = messages ? messages.nextElementSibling : null;
  if (!form || form.tagName !== 'FORM') return;

  form.addEventListener('ajax:success', function () {
    var textarea = form.querySelector('textarea[name="text"]');
    if (textarea) textarea.value = '';
  });
});
