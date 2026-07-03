# frozen_string_literal: true

module RedminefluxAgentos
  module Configuration
    # Gate 2 mandatory requirement (rao-020, docs/PHASE9-UI-UX-SPECIFICATION.md
    # §4.2): a credential-like configuration value is never rendered in the
    # Settings screen once saved — only a masked indicator and a "replace"
    # action. A generic Rails form/display helper bound directly to the
    # stored value would violate this by default; this is the dedicated
    # mechanism the Settings view must go through instead.
    #
    # v1 has no real credential key in active use (the Mock Provider's
    # `credentials` is always nil, docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md
    # §2.7) — this exists ahead of that need, forward-looking, so a v2
    # real-provider credential key is masked correctly from the moment it's
    # introduced rather than the Settings page needing a security-relevant
    # change at that point.
    module CredentialMasking
      # Allow-list of patterns identifying a credential-like key — matches
      # this project's established "allow-list, not deny-list" convention
      # for anything secret-adjacent (Phase 4 §7, rao-018 Gate 2 finding
      # #2). An unrecognized key is treated as an ordinary, safe-to-display
      # operational setting, not masked by default — masking every unknown
      # key would make the Settings page unusable for its many legitimate
      # plain values (`active_provider`, `logging_level`, etc.).
      #
      # The token pattern is deliberately NOT a bare `/token/i` — a real
      # v1 config key, `token_rules` (docs/PHASE3-MOCK-AI-PROVIDER-FOUNDATION.md
      # §12, "fixture_declared" — a behavior setting, not a secret), would
      # false-positive against that (caught by this ticket's own unit
      # test). Requiring "token" to be paired with a credential-indicating
      # word catches `access_token`/`api_token`/`refresh_token` while
      # leaving `token_rules`/`token_usages`-shaped keys alone.
      SENSITIVE_KEY_PATTERNS = [
        /credential/i, /api_key/i, /secret/i, /password/i,
        /(access|api|auth|refresh)_?token/i
      ].freeze

      MASKED_INDICATOR = '•••• configured'
      NOT_CONFIGURED_INDICATOR = 'Not configured'

      class << self
        def sensitive?(key)
          SENSITIVE_KEY_PATTERNS.any? { |pattern| key.to_s.match?(pattern) }
        end

        # @return the value to actually display in the Settings view —
        #   NEVER the raw stored value for a sensitive key, regardless of
        #   its shape (string, hash, etc.)
        def display_value(key, value)
          return value unless sensitive?(key)

          value.present? ? MASKED_INDICATOR : NOT_CONFIGURED_INDICATOR
        end
      end
    end
  end
end
