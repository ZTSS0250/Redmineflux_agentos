# frozen_string_literal: true

# Minimal plugin test bootstrap, matching the sibling redmineflux_devops
# plugin's own test/test_helper.rb pattern (docs/PHASE5-FOLDER-STRUCTURE.md
# §12) — delegates to Redmine core's test_helper for the Rails test
# environment, fixtures, and Minitest/Mocha setup.
#
# Scope note: redmineflux_devops's own test_helper.rb additionally
# symlinks plugin fixtures into Redmine's test/fixtures/ and defensively
# patches the test schema for migrations not yet replayed — none of that
# is needed yet here, since the Mock Provider's tests (rao-017, Phase 12)
# exercise fixture files under config/agentos/fixtures/mock_provider/
# directly and don't depend on ActiveRecord test fixtures. Add that
# machinery back in whichever future phase's tests first need it.
require File.expand_path("#{File.dirname(__FILE__)}/../../../test/test_helper")
