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
| T1 | Recon audit: acceptance checklist + risk list (read-only) | `scout` (explore) | P0 | — | ✅ done |
| T2 | Foundation: `project.godot`, autoloads, player, interactable base | `lead` | P0 | — | ✅ done |
| T3 | House scene + child/axe/door + day-3 empty room | `builder-core` (general) | P0 | T2 | ✅ done |
| T4 | Forest loop (3 trees, dusk, return, day2 obstacle, day3 spirit) + ending | `builder-forest` (general) | P0 | T2 | ✅ done |
| T5 | Atmosphere: per-day tint/overlay autoload (no scene edits) | `atmos` (general) | P2 | T2 | ✅ done (registered by lead) |
| T6 | Review: verify T3/T4/T5 against acceptance + smoke test (read-only) | `reviewer` (explore) | P0 | T3, T4, T5 | ✅ done |
| T7 | Integration: merge diffs, headless journey test, export, release | `lead` | P0 | T6 | 🟡 in progress (builds exported + verified; only the itch.io upload remains, needs a human) |

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
- 2026-10-17 · lead · **T1 done** (`scout`, read-only). Verdict: "skeleton ready" is FALSE; only the T2
  foundation existed. Full MVP→file map, top-5 risks and the 11-step smoke-test map delivered. Scout also
  caught the stale class cache (below).
- 2026-10-17 · lead · **BLOCKER found and fixed (class cache).** `extends Interactable` failed headlessly
  (`Parse Error: Could not find base class "Interactable"`). Cause: `.godot/global_script_class_cache.cfg`
  is gitignored and only rebuilt by the editor. Fix: `--headless --import` (prints `update_scripts_classes [ DONE ]`).
  Now `tools/probe_ext.tscn` → `PROBE_EXTENDS_INTERACTABLE_OK`. Documented in `CONTRACT.md`.
- 2026-10-17 · lead · **BLOCKER (open): export templates absent.** `%APPDATA%\Godot\export_templates` is
  empty, no `.tpz` on disk → no exported build possible. User approved downloading the official
  1.28 GB `Godot_v4.7.2-stable_export_templates.tpz`. In progress (background).
- 2026-10-17 · lead · Contract clarifications from the scout applied: `interact_range` 56→60, return
  trigger semantics, day-3 flow, spirit, `mark_used()` rule, `transition_to` without `await`, door gating,
  axe visual, canonical HUD string.
- 2026-10-17 · `atmos` · **T5 delivered** (`scripts/visual/atmosphere.gd`, layer 40, distinct per-day
  tints, day-2 fog). Self-test output recorded. Not yet registered as an autoload; safe to remove.
  Assets/IA: no third-party asset, nothing generated beyond the script itself.
- 2026-10-17 · lead · **T3 + T4 integrated.** `--headless --import` → exit 0; `res://tools/validate.tscn`
  → `PROBED_OK` for player/house/forest/ending + `VALIDATE_OK`, exit 0. `Atmosphere` registered as the
  5th autoload in `project.godot` (layer 40, under the HUD at 50).
- 2026-10-17 · lead · **NEW: end-to-end journey test** `tools/journey_test.tscn` (+ `.gd`). It drives the
  real scenes with real `InputEventAction` presses through the Input Map and asserts every step of the
  AGENTS.md §12 smoke test (child → axe → locked door → 3 trees → dusk → return → day 2 fog/obstacle →
  day 3 empty bed → spirit → ending → restart). Evidence:
  `& "<godot console>" --headless --path "<project>" res://tools/journey_test.tscn` →
  **`journey summary: 88 checks, 0 failures` / `JOURNEY_OK`, exit 0, no `SCRIPT ERROR`/`WARNING`.**
  Notable verified behaviours: holding `E` on a tree cannot over-count; the door is inert without the
  axe; day 2's branch both blocks the third tree and stops the player physically; the spirit stops the
  player at `x=540`; restarting resets day/wood/axe and brings the child back.
- 2026-10-17 · lead · Two *test-side* bugs found and fixed while writing the journey test (not game
  bugs): (1) the first version walked *away* from the spirit, so blocking was never exercised;
  (2) a message formatted `scene.name` on a scene the transition had already freed.
- 2026-10-17 · lead · **Visual verification tool added.** The Godot MCP playtest/screenshot capability is
  offline this session, so `tools/screenshots.tscn` (+`.gd`) renders every day of every scene to PNG and
  prints the mean luminance. It confirmed two defects the headless test cannot see (below).
- 2026-10-17 · `reviewer` · **T6 done** (read-only `explore`). Verdict: **no acceptance FAIL** on T3/T4/T5.
  It confirmed both visual findings of the lead and raised additional defects (§5.10-§5.13): dialogue could
  be opened from `_process`, missing `is_connected` guards in `forest_loop.gd`, an unreachable axe at the
  house spawn, a narrow HUD status label, a tautological day-2 colour assertion, and day-3 being so dark
  that the player/spirit were nearly invisible. It also flagged two things it could not verify by reading:
  real OS key mapping and class-name resolution inside the exported PCK.
- 2026-10-17 · lead · **Fix batch applied** (all defects from T6 + the two visual findings):
  day-3 no longer stacks three near-black layers (scene modulate `0.86,0.86,0.90`, overlay alpha `0.28`,
  `Atmosphere.day3_tint` alpha `0.44→0.30`); the ending label no longer collides with `[E] reiniciar`;
  the day-3 HUD note uses the HUD label instead of `_process`; `is_connected` guards added; house spawn
  moved to `Vector2(180, 600)` so the axe is in range; HUD status label widened (`offset_right` 520→900);
  the tautological day-2 assertion replaced; `stretch/aspect` set to `keep`; `embed_pck=true`.
  Evidence after the fix batch: `--headless --import` exit 0 · `tools/validate.tscn` → `VALIDATE_OK`
  exit 0 · `tools/journey_test.tscn` → **`journey summary: 92 checks, 0 failures` / `JOURNEY_OK`**, exit 0.
- 2026-10-17 · lead · **Export templates blocker CLOSED.** Official `4.7.2.stable` templates installed to
  `%APPDATA%\Godot\export_templates\4.7.2.stable\` (35 files).
- 2026-10-17 · lead · **Windows build exported and run outside the editor** (AGENTS.md §12 step 11).
  Command: `& "<godot console>" --headless --path . --export-release "Windows Desktop" "build\windows\A Mother of Nightmares.exe"`
  (the output directory must already exist). Result: `build/windows/A Mother of Nightmares.exe`
  (109,227,752 bytes, PCK embedded). Launched it: a real window titled "A Mother of Nightmares" renders
  the house in day 1 with the HUD `Dia 1/3 — Madeira 0/3` and the child's dialogue box
  (screenshot: `%TEMP%\opencode\screens\exported_build_window.png`). Engine log on the target machine:
  `D3D12 12_0 - Forward+ - Using Device #0: NVIDIA GeForce RTX 3050 6GB Laptop GPU`, **no `SCRIPT ERROR`**.
- 2026-10-17 · lead · **Web (itch.io) build exported.** Command: `... --export-release "Web" "build/web/index.html"`
  → exit 0. Files: `index.html`, `index.js`, `index.wasm` (39.5 MB), `index.pck` (59 KB) + icons/worklets.
- 2026-10-17 · lead · **Exclusion filter verified.** `addons/*, tools/*` are excluded from both presets.
  The only `godot_mcp` string inside `index.pck` is `res://addons/godot_mcp/plugin.cfg` coming from the
  packed `.godot/uid_cache.bin` **cache mapping** — no addon code (`plugin.gd`, etc.) is packed, and no
  `tools/` file is packed. The `GDPC` marker confirms the Windows exe has the PCK embedded.
- 2026-10-17 · lead · **Input Map confirmed present in the shipped builds.** `move_left`, `move_right`,
  `interact` and the prompt strings ("Falar com o filho", "Pegar o machado") are present in `index.pck`
  and in the embedded PCK of the exe.
- 2026-10-17 · lead · **Exported-binary robustness check.** Injected OS key events (`E` ×3, hold `D` 4 s,
  hold `A` 3 s, arrows) into the running exported build: the process stayed alive and `Responding=True`
  through every phase and its stdout contained only the engine banner + renderer line — **no `SCRIPT ERROR`,
  no warning**. *Limitation (honest):* the host runs at 125% DPI and other desktop windows overlap the
  captured region, so the on-screen *effect* of those injected keys could not be recorded reliably; the
  gameplay effect of the same keys is covered by the headless journey test, which presses through the real
  Input Map. See `ASSETS_AND_AI.txt` §7.
- 2026-10-17 · lead · **Freeze for release.** `builder-forest` (the last writer to the shipped tree) was
  asked to stop and acknowledged; no agent has write access to the frozen tree after this point.
- 2026-10-17 · lead · **Web (itch.io) build smoke-tested locally.** Served `build/web` through a local
  static server and loaded it in a browser: the game boots, renders on
  `OpenGL ES 3.0 (WebGL 2.0) — Compatibility`, single-threaded, and starts on the correct scene
  (HUD `Dia 1/3 — Madeira 0/3`, house, axe prompt `[E] Pegar o machado`). `application/run/main_scene`
  inside `index.pck` was re-verified as `res://scenes/house_interior.tscn`.
  - **Keyboard/action verification in the shipped build:** dispatching a single `interact` (`E`) press to
    the canvas at spawn removed the axe visual **and** cleared the prompt — i.e. the Input Map and the
    axe-pickup flow work inside the exported Web build. This closes the reviewer's "real key mapping only
    proven indirectly" item for the shipped builds.
  - `variant/thread_support=false` in the Web preset, so the build does **not** need COOP/COEP headers and
    will run in itch.io's iframe without SharedArrayBuffer.
  - Note (process): two early captures appeared to show the forest on day 2 and the ending from a fresh
    load. They were **stale Review-pane frames**, not the build's start state — re-tested on a second,
    cache-free port and the game consistently starts at the house on day 1, then behaved correctly under
    the `E` press. Recorded here so the discrepancy is not mistaken for a bug in the audit.
  - Limitation: sustained key *holds* could not be verified this way (the page has no OS focus, and Godot
    clears held keys on blur), so continuous walking in the Web build is covered by the headless journey
    test and the Windows build, not by the browser run.
- 2026-10-17 · lead · **itch.io upload package prepared.** `build/itchio/a-mother-of-nightmares-web.zip`
  (10,264,260 bytes) with `index.html` at the ZIP root and only the files the runtime needs
  (`index.html/js/wasm/pck`, the two icons and the two audio worklets — the stray `*.import` sidecars that
  `--headless --import` created inside `build/web` are excluded). Upload as an HTML5 game on itch.io.
  Build artifacts stay gitignored; they are regenerated with the commands in `CONTRACT.md` §9.
