# Claude Code Bash Sandbox

## Issue
Claude Code runs every Bash command inside a bubblewrap sandbox. Agents keep
hitting its limits mid-task and either work around them (run tools straight
from `node_modules`, retry outside the sandbox) or misread them as repo
problems (a "stale" `.git/config.lock`). The friction falls into seven groups:
pnpm, git config writes, localhost, phantom untracked files, the Docker
socket, the network guard vanishing when the sandbox is disabled, and
`$TMPDIR` changing between sandboxed and unsandboxed commands. pnpm and git
config writes are fixed (2026-10-26); the rest are open.

Field report (ssc-explorer review run, #424–#426, 2026-10-26) hit all six:
db gates skipped, every pnpm gate failed, six `fix/ssc-ce2-bug-0*` branches
created without upstream, and all local-stack testing (psql, curl to dev
servers, `db:rebuild`, Auth admin call, Playwright) ran unsandboxed — which
let four sign-in attempts reach the **hosted** Supabase project via
`apps/frontend/.env` with no warning.

Report from the #432 review (ssc-explorer, 2026-10-26): `gh pr checkout`
and `git checkout -B` failed on the upstream write (Problem 2); all five
gates failed on pnpm; `pnpm build`, `docker build/run` and `poetry run` all
needed the sandbox off (poetry cause not investigated). Its closing claim
that sandboxed git "leaves `.git/config.lock` behind" is wrong — the mask
exists only inside the sandbox — and so is its suggestion to allow the
Docker socket (see Problem 5).

Report from the #428 review (ssc-explorer, 2026-10-26): every `gates.sh`
gate failed on pnpm before running any code; `next dev`, curl probes to
`localhost:3000`/`:54321` and the Supabase admin API all needed the sandbox
off; a dev server lost its worktree because `$TMPDIR` differed (Problem 7);
and Turbopack refused a worktree with borrowed `node_modules` (Problem 1).

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

### Stray per-mount stores (cleaned up 2026-10-26)
pnpm hardlinks from `~/.local/share/pnpm/store` into `node_modules`. Across
mounts that fails, so pnpm assumes another drive and creates a store at the
mount root: `~/tandemhub/.pnpm-store` (created Oct 2, 14 MB). Works, just
duplicates. Safe to delete. Deleted 2026-10-26; pnpm may recreate it.

### Pinned pnpm version fails (the #424–#426 gate failures) — FIXED
Any project with a `packageManager` pin (ssc-explorer: `pnpm@10.33.0`) makes
pnpm 12 switch engine, which fails everywhere in the sandbox:

```
ERR_PNPM_STORE_DIR_OPEN_OPERATION_LOCK
  × lock the package-manager engine store
  ╰─▶ Failed to open the store operation lock at "pnpm-store-operation-locks":
      Read-only file system (os error 30)
```

Cause (found 2026-10-26): pnpm 12.9+ keeps its lock dirs in
`$XDG_RUNTIME_DIR` — `/run/user/1000/pnpm-store-operation-locks-1000` and
`/run/user/1000/pnpm-dir-locks-1000` — which is read-only in the sandbox.
(12.6–12.8 used `/tmp/…` instead.) The engine store under
`~/.local/share/pnpm/package-manager-store` is a red herring; it was already
writable. Confirmed: `XDG_RUNTIME_DIR=$TMPDIR pnpm --version` with the pin
works inside the sandbox.

**Fix:** add those two exact dirs to `allowWrite`. Not the whole
`/run/user/1000` — it holds the Wayland, D-Bus and gpg-agent sockets.
`/run/user` is a tmpfs, so after a reboot the dirs are gone until pnpm runs
once outside the sandbox; quick fallback: prefix with `XDG_RUNTIME_DIR=$TMPDIR`.

**Status: fixed (2026-10-26, 2.1.311).** Applied live, no restart needed;
`pnpm@10.33.0` runs inside the sandbox.

Workaround agents used before the fix: run `eslint`, `tsc`, `jest` straight from
`apps/frontend/node_modules/.bin`. Skips pnpm, but also skips the review
script's gate wrapper.

Knock-on in worktrees: `pnpm install` can't run there either, so agents
symlink the main checkout's `node_modules` in. ESLint/tsc/jest cope, but
Turbopack refuses it (`Could not find the Next.js package
(next/package.json)`), so `next dev` in such a worktree fails. Webpack
(`next dev --webpack`) untested. The real fix is the lock dir above.

## Problem 2: git config writes — FIXED

Anything that writes `.git/config` fails in the sandbox:
`git push -u`, `git branch -u`, `git switch -c` with tracking, `gh pr checkout`,
`git remote add`, `git config …`, some `git worktree` setups.

Seen in practice (ssc-explorer): `gh pr checkout` → `could not lock config
file`; on #432, `failed to run git: exit status 1` after a
`--set-upstream-to` hint, and a fallback `git checkout -B` that didn't
switch either. Branches created with no upstream, which then has to be fixed
outside the sandbox (`git branch -u origin/<b> <b>`).

Reproduced 2026-10-26 in the chezmoi repo (same behaviour in any repo used
as the working directory):

- Any command that sets up tracking (`git branch -t`, `git checkout -B <b>
  origin/<b>`, `git switch -c` from a remote branch — tracking is the default
  there) fails with `could not lock config file .git/config: File exists`.
- It fails **half-done**: the branch ref is created, but `checkout`/`switch`
  then exits 1 **without switching**. That matches #432: the failed
  `gh pr checkout` left a local branch behind and HEAD unchanged, and the
  `git checkout -B` fallback failed the same way.
- `--no-track` works fully inside the sandbox:

  ```sh
  git fetch origin pull/<n>/head
  git switch --no-track -C <branch> FETCH_HEAD
  ```

  Fine for reviewing; set the upstream later outside the sandbox if needed.
  `gh pr checkout <n> --detach` should also avoid the config write (untested).
- `git branch -D` succeeds but warns `update of config-file failed` (it
  tries to drop the branch's config section).

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
**Status: fixed (2026-10-26, 2.1.311).** Needs a full restart: `allowWrite`
changes take effect live, but `allowGitConfig` only applies after
restarting Claude Code. After a restart, `git branch -t` and
`git config --local` writes work inside the sandbox. One report says the key
is ignored entirely
([agents-adapter #48](https://github.com/metrodiesign/agents-adapter/pull/48),
2.1.261), so on older versions use `--no-track` (below).
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

Same for `curl localhost:3000` (dev server) and `localhost:54321` (Supabase
API/Auth admin). Starting `next dev` also needed the sandbox off.

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

Full set can be ~21 entries at the repo root: also `.gitmodules`, `.zshrc`,
`.profile`, `.zprofile`, `.gitconfig`, `.mcp.json`, `.ripgreprc`, `.idea`,
`.vscode`, and `.claude/scheduled_tasks.json`, `.claude/workflows`. From inside the sandbox they're char devices `1, 3`
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
**/.claude/scheduled_tasks.json
**/.claude/workflows/
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

## Problem 7: `$TMPDIR` differs with the sandbox off

Inside the sandbox `$TMPDIR` is `/tmp/claude-1000`; in a command run with the
sandbox disabled it points somewhere else. So a worktree created sandboxed at
`$TMPDIR/pr428` isn't at `$TMPDIR/pr428` for an unsandboxed `cd` — in #428 the
dev server missed the worktree and wrote its log elsewhere.

**Fix:** use absolute paths (`/tmp/claude-1000/pr428`) for anything shared
between sandboxed and unsandboxed commands. Clean up such worktrees with
`git worktree remove` afterwards.

## Not sandbox: shared checkout between sessions

During #428 the main ssc-explorer checkout switched branch mid-review
(18:01:09, to `feat/ssc-ce2-t04-01-build-and-publish-versioned-images`).
Cause: the parallel #432 session, after its sandboxed checkout failed
(Problem 2), re-ran `git checkout` with the sandbox off in the same
checkout. So an end-to-end probe in #428 ran the wrong code. Concurrent sessions on one repo should
each work in their own worktree, not the main checkout.

## Config changes

In `dot_claude/private_settings.json` (2026-10-26):

```json
"filesystem": {
  "allowWrite": ["/tmp", "~/.cache", "~/.npm", "~/.local/state",
    "~/tandemhub", "~/coding", "~/.local/share/pnpm",
    "/run/user/1000/pnpm-store-operation-locks-1000",
    "/run/user/1000/pnpm-dir-locks-1000"],
  "allowGitConfig": true
}
```

Then: `chezmoi apply ~/.claude/settings.json` (outside the sandbox), restart
Claude Code, `rm -rf ~/tandemhub/.pnpm-store`.

Still proposed, pending the `excludedCommands` caveat (Problem 3): add
`"psql"` to `excludedCommands`.
