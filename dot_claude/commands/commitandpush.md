commit this in atomic conventional commits for each one

use the new-pr slash command to generate the PR description

then create a PR into `main` using the GH CLI with that description, and request users maxitect and right-handed as reviewers

if we have been working on a specific ticket, end the description with a plain `Closes TOZN-<n>` / `Closes BOZN-<n>` line (not in backticks) — the Monday sync workflow moves the ticket to Code Review from that line, so don't move it by hand
