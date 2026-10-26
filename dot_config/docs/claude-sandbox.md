# Claude Code Bash Sandbox

## Issue
Claude Code runs every Bash command inside a bubblewrap sandbox. Agents keep
hitting its limits mid-task and either work around them (run tools straight
from `node_modules`, retry outside the sandbox) or misread them as repo
problems (a "stale" `.git/config.lock`). The friction falls into six groups:
pnpm, git config writes, localhost, phantom untracked files, the Docker
socket, and the network guard vanishing when the sandbox is disabled.

Field report (ssc-explorer review run, #424–#426, 2026-10-26) hit all six:
db gates skipped, every pnpm gate failed, six `fix/ssc-ce2-bug-0*` branches
created without upstream, and all local-stack testing (psql, curl to dev
servers, `db:rebuild`, Auth admin call, Playwright) ran unsandboxed — which
let four sign-in attempts reach the **hosted** Supabase project via
`apps/frontend/.env` with no warning.

Config lives in `dot_claude/private_settings.json` → `~/.claude/settings.json`,
under `sandbox`. Agents can't edit it themselves: the auto-mode classifier
blocks it as self-modification. Edit, then `chezmoi apply ~/.claude/settings.json`
and restart the session.

## System details

- Claude Code 2.1.310, Linux (bubblewrap)
- pnpm 12.9.1 (Rust binary) via `PNPM_HOME=~/.local/share/pnpm`
- Projects under `~/tandemhub` and `~/coding`

## Current config

```json
"sandbox": {
  "enabled": true,
  "autoAllowBashIfSandboxed": true,
  "network": {
    "allowedDomains": ["github.com", "api.github.com", "raw.githubusercontent.com",
      "objects.githubusercontent.com", "codeload.github.com", "registry.npmjs.org",
      "registry.yarnpkg.com", "pypi.org", "files.pythonhosted.org", "crates.io",
      "static.crates.io", "proxy.golang.org", "sum.golang.org"],
    "allowLocalBinding": true
  },
  "filesystem": {
    "allowWrite": ["/tmp", "~/.cache", "~/.npm", "~/.local/state",
      "~/tandemhub", "~/coding", "~/.local/share/pnpm"]
  },
  "excludedCommands": ["sudo", "chezmoi", "pacman", "paru", "yay",
    "systemctl", "docker", "supabase"]
}
```

`excludedCommands` run outside the sandbox entirely.

## How the sandbox is built (what matters)

- **Each `allowWrite` path is its own bind mount.** Same disk, but hardlinks
  between mounts fail (`EXDEV`). Everything else is read-only (`EROFS`).
- **The working directory's git internals are masked read-only**:
  `.git/config`, `.git/config.lock` (a `/dev/null` char device, `1, 3`, owner
  `nobody`), `.git/config.worktree`, `.git/hooks`. Only inside the sandbox —
  nothing is left on disk.
- **Own network namespace.** Loopback inside is not the host's. Outbound
  traffic only via the domain-filtering proxy. `allowLocalBinding` is ignored
  on Linux.

## Problem 1: pnpm

### Stray per-mount stores
pnpm hardlinks from `~/.local/share/pnpm/store` into `node_modules`. Across
mounts that fails, so pnpm assumes another drive and creates a store at the
mount root: `~/tandemhub/.pnpm-store` (created Oct 2, 14 MB). Works, just
duplicates. Safe to delete.

### Pinned pnpm version fails (the #424–#426 gate failures)
Any project with a `packageManager` pin (ssc-explorer: `pnpm@10.33.0`) makes
pnpm 12 switch engine, which fails everywhere in the sandbox:

```
ERR_PNPM_STORE_DIR_OPEN_OPERATION_LOCK
  × lock the package-manager engine store
  ╰─▶ Failed to open the store operation lock at "pnpm-store-operation-locks":
      Read-only file system (os error 30)
```

Reproduced from `$TMPDIR`, `~/coding`, `~/.cache` and `~/.local/share/pnpm` —
so the lock is outside every `allowWrite` path. pnpm only prints the relative
name and `strace` isn't installed, so the real path is still **unknown**.

Find it (outside the sandbox — `!` prefix in Claude Code):

```sh
d=$(mktemp -d); echo '{"packageManager":"pnpm@10.33.0"}' > $d/package.json
touch $d/.m; (cd $d && pnpm --version)
find ~ -xdev -newer $d/.m -path '*pnpm*' 2>/dev/null | head
```

**Fix:** add that directory to `allowWrite`.

Workaround agents use meanwhile: run `eslint`, `tsc`, `jest` straight from
`apps/frontend/node_modules/.bin`. Skips pnpm, but also skips the review
script's gate wrapper.

## Problem 2: git config writes

Anything that writes `.git/config` fails in the sandbox:
`git push -u`, `git branch -u`, `git switch -c` with tracking, `gh pr checkout`,
`git remote add`, `git config …`, some `git worktree` setups.

Seen in practice: `gh pr checkout` → `could not lock config file` (needs a
follow-up `git switch`); branches created with no upstream, which then has to
be fixed outside the sandbox (`git branch -u origin/<b> <b>`).

This is deliberate: a writable `.git/config` could set `core.hooksPath` or
`core.fsmonitor` and run code unsandboxed the next time git runs outside.

**Fix:** Claude Code has a setting for exactly this:

```json
"filesystem": {
  "allowWrite": [...],
  "allowGitConfig": true
}
```

Schema description: *"Allow writes to .git/config files (default: false).
Enables git remote URL updates while keeping .git/hooks protected."*
Trade-off: config keys like `core.hooksPath` become writable. The binary
references git config pinning/injection that likely neutralises these — not
verified.

Don't add `git` to `excludedCommands` — that drops the sandbox for every git
command.

## Problem 3: localhost services

Local Supabase Postgres (`127.0.0.1:54322`), dev servers, etc. are unreachable:

```
psql: error: connection to server at "127.0.0.1", port 54322 failed: Connection refused
```

The sandbox's `127.0.0.1` is its own. On Linux there is **no setting** to
expose the host's loopback (`allowLocalBinding` only applies on macOS/Windows).

**Fix:** add the client commands to `excludedCommands`, same as `supabase` and
`docker` already are:

```json
"excludedCommands": [..., "psql"]
```

Matching is on the command prefix, so `psql …` works but `cd x && psql …` or
`foo | psql` may still be sandboxed.

**Caveat — `excludedCommands` isn't being honoured.** On 2026-10-26 a bare
`chezmoi apply ~/.config/docs/claude-sandbox.md` (no `&&`/`|`) still ran
sandboxed and failed on its state db:

```
chezmoi: open /home/jack/.config/chezmoi/chezmoistate.boltdb: read-only file system
```

Same symptom seen 2026-09-25. So adding `psql` here may not help either —
check this first (e.g. `/sandbox` in Claude Code). Likely cause: exclusion
not applied in auto mode. Unverified. Anything else that needs localhost (curl
to a dev server, Playwright) gets retried unsandboxed via the classifier.

## Problem 4: phantom untracked files in lazygit

While a sandboxed command runs, lazygit/`git status` show untracked:

```
?? .bashrc
?? .bash_profile
?? .claude/agents/
?? .claude/commands/
?? .claude/launch.json
?? .claude/loop.md          ← "error: Could not access '.claude/loop.md'"
?? .claude/output-styles/
?? .claude/routines/
```

Full set can be ~21 entries at the repo root: also `.zshrc`, `.profile`,
`.zprofile`, `.gitconfig`, `.mcp.json`, `.ripgreprc`, `.idea`, `.vscode`, more
`.claude/*`. From inside the sandbox they're char devices `1, 3`
(`/dev/null`) with a fixed old mtime (Oct 23), not real files. Same thing
showed in `ls -a` of the chezmoi repo itself while `git status` was clean.
A shell prompt's untracked count jumps (`?22` → `?1`) depending on whether it
renders mid-command.

**Don't `git clean` them.** An agent once called them "leftovers" and
suggested it — unverified and wrong; they vanish on their own.

Expected, harmless. These are protected paths that don't exist in the repo.
bubblewrap needs a mount target to put the read-only/`/dev/null` mask on, so
it creates empty placeholders for the duration of the command and removes
them after. lazygit just refreshes mid-command. Checked 2026-10-26: nothing
left on disk in ssc-explorer afterwards.

**Fix (noise only):** add to the global git ignore `~/.config/git/ignore`
(not chezmoi-managed yet; already has `**/.claude/.cc-writes/`):

```
**/.claude/agents/
**/.claude/commands/
**/.claude/output-styles/
**/.claude/routines/
**/.claude/loop.md
**/.claude/launch.json
```

Leave dotfiles (`.bashrc`, `.zshrc`, `.gitconfig`, `.mcp.json`, `.idea`,
`.vscode`, …) out — a project could have real ones, and ignoring them
globally would hide genuine changes (this chezmoi repo is one).

Related: `.gitmodules` is also protected, so every checkout prints
`Permission denied` warnings for it inside the sandbox. Harmless noise.

## Problem 5: no Docker socket

`supabase start` fails with `permission denied … /var/run/docker.sock`.
Unix sockets are blocked by default (seccomp filter), and the docker socket
is effectively root on the host — don't open it broadly.

`docker` and `supabase` are already in `excludedCommands`, which should run
them unsandboxed. That it still failed is more evidence for the
`excludedCommands` caveat above. (The supabase CLI also wasn't installed in
that run — separate, not sandbox.)

**Fix:** sort out `excludedCommands` first. Avoid `allowAllUnixSockets` /
allowing `docker.sock` — that is a full sandbox escape.

## Problem 6: disabling the sandbox drops the network guard

Consequence of Problem 3 + 5, not a sandbox bug. Once a command runs with
the sandbox off (to reach localhost), the `allowedDomains` proxy no longer
applies — it can reach any host. In the field report, local-stack testing
with the sandbox off sent sign-in attempts to the **hosted** Supabase project
because `apps/frontend/.env` pointed there.

**Mitigations:**
- Local testing should use a local-only env (`.env.local` / `supabase status`
  values) so a stray unsandboxed run can't hit hosted projects.
- Keep unsandboxed runs to single, specific commands (`psql …`, `curl
  localhost…`), not whole scripts that load `.env`.
- Hosted Supabase hostnames are deliberately not in `allowedDomains`; keep it
  that way.

## Proposed config

```json
"filesystem": {
  "allowWrite": ["/tmp", "~/.cache", "~/.npm", "~/.local/state",
    "~/tandemhub", "~/coding", "~/.local/share/pnpm",
    "<pnpm engine lock dir — see Problem 1>"],
  "allowGitConfig": true
},
"excludedCommands": ["sudo", "chezmoi", "pacman", "paru", "yay",
  "systemctl", "docker", "supabase", "psql"]
```

Then: `chezmoi apply ~/.claude/settings.json`, restart Claude Code,
`rm -rf ~/tandemhub/.pnpm-store`.
