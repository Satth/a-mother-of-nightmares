# TFBOARD.md — shared task board (`a-mother-of-nightmares`)

> **Tooling note (honest limitation).** OpenCode exposes **no Ensemble/team/task-board tool** in this
> session. The catalog (156 tools: browser, context7, github, godot, opencode, playwright, serena)
> has no team, board, priority or dependency tool. Multi-agent work here uses the **`subagent`** tool
> (`explore` / `general` only). This file **is** the board: IDs, owner, priority, dependencies and
> acceptance criteria. It is versioned in Git so the jam can audit it.

**Lead / integrator:** the main session (owns `project.godot`, contract, integration, release).
**Legend:** P0 = blocks the playable journey · P1 = required by MVP · P2 = polish.

| ID | Task | Owner (agent) | Priority | Depends on | Status |
|----|------|---------------|----------|-----------|--------|
| T1 | Recon audit: acceptance checklist + risk list (read-only) | `scout` (explore) | P0 | — | ⏳ |
| T2 | Foundation: `project.godot`, autoloads, player, interactable base | `lead` | P0 | — | ✅ done |
| T3 | House scene + child/axe/door + day-3 empty room | `builder-core` (general) | P0 | T2 | ⏳ |
| T4 | Forest loop (3 trees, dusk, return, day2 obstacle, day3 spirit) + ending | `builder-forest` (general) | P0 | T2 | ⏳ |
| T5 | Atmosphere: per-day tint/overlay autoload (no scene edits) | `atmos` (general) | P2 | T2 | ⏳ |
| T6 | Review: verify T3/T4/T5 against acceptance + smoke test (read-only) | `reviewer` (explore) | P0 | T3, T4, T5 | ⏳ |
| T7 | Integration: merge diffs, headless journey test, export, release | `lead` | P0 | T6 | ⏳ |

**Conflict policy:** the file-ownership table in `CONTRACT.md` §1 is binding. Two agents must never
write the same file. `project.godot`, `CONTRACT.md`, `TFBOARD.md`, `ASSETS_AND_AI.txt` are **lead-only**.

---

## Acceptance criteria

**T1 (scout)** — read-only report with: (a) explicit list of what is missing vs AGENTS.md §5 MVP,
(b) top 5 delivery risks ranked, (c) a checklist mapping AGENTS.md §12 smoke-test steps 1-11 to
concrete node/scene evidence. No file writes.

**T2 (lead)** — `project.godot` parses; `InputMap.has_action` true for the 3 actions; 4 autoloads
instantiate; `player.tscn` loads; `tools/validate_project.gd` exits 0.

**T3 (builder-core)** — `house_interior.tscn` loads headless without errors; child appears on days
1-2 and is absent on day 3; empty bed detail visible on day 3; axe sets `GameState.has_axe`; door is
inert without the axe and transitions to the forest with it.

**T4 (builder-forest)** — `forest.tscn` loads headless; each of the 3 trees adds exactly 1 wood once
(holding `E` cannot over-count); dusk triggers at `wood_complete()`; return on day 1/2 advances exactly
one day and goes home; day 2 shows a visible, solvable obstruction; day 3 spawns the spirit, blocks the
return and reaches `ending.tscn`; ending resets state and returns to day 1.

**T5 (atmos)** — `atmosphere.gd` is an autoload that reacts to `GameState.day_changed` and applies a
distinct tint/overlay per day (day 1 warm, day 2 cold/foggy, day 3 near-monochrome). Touches **no**
scene or gameplay file. Cannot break the flow if removed.

**T6 (reviewer)** — read-only report: per-criterion pass/fail with the exact evidence (command +
output/excerpt), every regression found, and an explicit "cannot verify" list. No file writes.

**T7 (lead)** — full journey reproduced by running the built project; `ASSETS_AND_AI.txt` updated;
build exported and opened outside the editor; release committed and pushed.

---

## Log

- 2026-10-17 · lead · Recon complete. Project had **no game content** (docs + `addons/godot_mcp` only).
  Git initialised, remote `origin` integrated (README preserved), pushed. Board created.
- 2026-10-17 · lead · Godot MCP bridge is **offline for this session** (3 concurrent `godot-editor-mcp`
  stacks; another process holds port 9080). Cannot be revived from inside the session; validation is
  done through the Godot CLI headless instead.
- 2026-10-17 · lead · **T2 done.** Evidence: `--headless res://tools/validate.tscn` → `VALIDATE_OK`, exit 0.
  Input actions `move_left/move_right/interact` present; autoloads `GameState/Dialogue/HUD/SceneTransition`
  up; `GameState` behaviour checks (clamp, day advance, day cap 3, child absent day 3, reset) pass;
  `player.tscn` loads and instantiates. World locked to a single 1280x720 screen, ground `y=600`.
