# CONTRACT.md — A Mother of Nightmares (interface frozen by the lead)

**Engine:** Godot **4.7.2-stable** (`C:\Users\Usuario\Downloads\Compressed\Godot_v4.7.2-stable_win64.exe`).
**Do not change** `config_version` or `config/features`.
**Validate the foundation headless with (must be run as a SCENE so autoloads exist):**
```
& "C:\Users\Usuario\Downloads\Compressed\Godot_v4.7.2-stable_win64_console.exe" --headless --path "C:\Users\Usuario\Documents\a-mother-of-nightmares" res://tools/validate.tscn
```
Expected: `VALIDATE_OK` and exit code 0.
**Validate a single scene headless with:**
```
& "C:\Users\Usuario\Downloads\Compressed\Godot_v4.7.2-stable_win64_console.exe" --headless --path "C:\Users\Usuario\Documents\a-mother-of-nightmares" res://scenes/forest.tscn --quit-after 5
```

> This file is the single source of truth for cross-module interfaces. If you need a change,
> **stop and report to the lead** instead of inventing a new API.

---

## 1. File ownership (do NOT edit files you do not own)

| Owner | Files / folders |
|---|---|
| **lead** | `project.godot`, `CONTRACT.md`, `TFBOARD.md`, `ASSETS_AND_AI.txt`, `tools/**`, `scripts/autoload/**`, `scripts/player/**`, `scenes/player/**` |
| **builder-core** | `scenes/house_interior.tscn`, `scripts/house_interior.gd`, `scenes/interactables/child.tscn`, `scenes/interactables/axe.tscn`, `scenes/interactables/door.tscn`, `scripts/interactables/{child,axe,door}.gd` |
| **builder-forest** | `scenes/forest.tscn`, `scripts/forest_loop.gd`, `scenes/interactables/{tree,obstacle,spirit}.tscn`, `scripts/interactables/{tree,obstacle,spirit}.gd`, `scenes/ending.tscn`, `scripts/ending.gd` |
| **atmos** | `scripts/visual/atmosphere.gd`, `assets/art/**` |
| **scout / reviewer** | read-only, no writes |

---

## 2. Autoloads (already registered in `project.godot`)

### `GameState` — `res://scripts/autoload/game_state.gd`
```gdscript
signal day_changed(day: int)
signal wood_changed(wood: int, target: int)
signal axe_changed(has_axe: bool)

const WOOD_TARGET := 3
const MAX_DAY := 3

var day: int        # always 1..3
var wood: int       # 0..WOOD_TARGET
var has_axe: bool

func reset() -> void                        # new game -> day=1, wood=0, has_axe=false (+signals)
func set_axe(value: bool = true) -> void
func add_wood(amount: int = 1) -> int       # returns how many were ACTUALLY counted (0..n)
func wood_complete() -> bool                # wood >= WOOD_TARGET
func child_present() -> bool                # true on day 1 and 2, false on day 3
func advance_day() -> void                  # day+1 (capped at MAX_DAY); resets wood=0, has_axe=false
```

### `Dialogue` — `res://scripts/autoload/dialogue.gd` (CanvasLayer, layer 100)
```gdscript
signal finished
func is_active() -> bool
func show_lines(lines: Array) -> void   # [] closes immediately and emits finished
```
While active it consumes the `interact` action and calls `set_input_as_handled()`.
Advancing dialogue and triggering an interactable in the same frame must not happen.

### `HUD` — `res://scripts/autoload/hud.gd` (CanvasLayer, layer 50)
```gdscript
func set_prompt(text: String) -> void   # renders "[E] <text>"; empty clears
func clear_prompt() -> void
func set_status(text: String) -> void   # top-left status line, e.g. "Dia 1/3 — Madeira 0/3"
```

### `SceneTransition` — `res://scripts/autoload/scene_transition.gd` (CanvasLayer, layer 200)
```gdscript
signal transition_finished
func is_busy() -> bool
func transition_to(scene_path: String, fade_out := 0.35, fade_in := 0.35) -> void
```
**Call it WITHOUT `await` from scene scripts.** `change_scene_to_file` frees the caller node, so
`await SceneTransition.transition_to(...)` can resume on a freed node and error. Fire and forget.

### `Atmosphere` — `res://scripts/visual/atmosphere.gd` (CanvasLayer, layer 40)
Per-day colour-grade overlay only. Officially RECOMMENDED but **optional**: registered by the lead and
safe to remove. It reacts to `GameState.day_changed` and reads nothing else. Nothing may depend on it.
**Status: REGISTERED** in `project.godot` (5th autoload, integrated with T5).

---

## 3. Input Map actions (already in `project.godot`)

| Action | Keys |
|---|---|
| `move_left` | `A`, `Left` |
| `move_right` | `D`, `Right` |
| `interact` | `E` |

Never check raw keycodes in gameplay scripts — always use these actions.

---

## 4. Player — `res://scenes/player/player.tscn`

Node tree:
```
Player (CharacterBody2D, groups=["player"])   script: scripts/player/player_controller.gd
├── Visual (ColorRect)          # placeholder body; left at origin, offsets -12..12 / -48..0
└── CollisionShape2D            # RectangleShape2D 24x48, position (0,-24)
```
Public API on `player_controller.gd`:
```gdscript
@export var speed := 220.0
@export var interact_range := 60.0
var input_enabled := true
var current_target: Node = null
func set_input_enabled(v: bool) -> void
```
The controller already: reads the input actions, finds the nearest eligible node in group
`interactable` within `interact_range`, drives `HUD.set_prompt`, and calls `interact(self)` on
`interact` press. **Scenes just need to instantiate `player.tscn` and place it.**

---

## 5. Interactable base — `res://scripts/interactions/interactable.gd`

`class_name Interactable extends Node2D`. Concrete interactables **must have this script as the
node's script** (or extend it) and **must declare `groups=["interactable"]` in the `.tscn`**:

```gdscript
@export var prompt_text := "Interagir"
@export var one_shot := false
func can_interact() -> bool          # false when one_shot and already used
func get_prompt() -> String          # HUD shows "[E] " + this
func interact(by: Node) -> void      # override in subclass
func mark_used() -> void
```

Subclass `.tscn` skeleton:
```
[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/interactables/child.gd" id="1"]

[node name="Child" type="Node2D" groups=["interactable"]]
script = ExtResource("1")
prompt_text = "Falar com o filho"
```
If a subclass defines `_ready()`, it **must** call `super._ready()`.
Position = the interaction point (the player must be within `interact_range` of it).

---

## 6. Scene flow contract

```
scenes/house_interior.tscn   (main scene / start of every day)
        │  get axe + talk to child (days 1-2) + use door  → SceneTransition.transition_to(forest)
        ▼
scenes/forest.tscn
        │  walk right, cut 3 trees (GameState.add_wood) → dusk → walk back left → return trigger
        │
        ├─ day 1/2: on reaching the return trigger → GameState.advance_day() → transition_to(house_interior)
        └─ day 3:   blocked by the spirit → spirit encounter → transition_to(ending)
        ▼
scenes/ending.tscn
        final image + fade + "[E] reiniciar"  → GameState.reset() + transition_to(house_interior)
```

Rules (from AGENTS.md §6):
- `day` only ever 1..3; a successful return advances exactly one day.
- Cutting is counted **per interaction**; holding `interact` must not add wood repeatedly.
- The door must not work before the axe is obtained.
- Day 3 ends at the spirit; no impossible task after it appears.

### Binding clarifications (freeze — added after the scout audit)

- **`mark_used()` is the subclass's job.** `Interactable.interact()` is a no-op and does NOT auto-mark.
  Every `one_shot` interactable MUST call `mark_used()` inside its own `interact()`.
- **Dialogue double-trigger is solved by input order.** The player calls `set_input_as_handled()` after
  `interact()`, and scene nodes receive `_unhandled_input` *before* autoloads, so the same `E` press
  cannot both open and advance the dialogue. Do not bypass the player to open dialogue from `_process`.
- **Door gating is via `can_interact()`**: `door.gd` overrides it to return `GameState.has_axe`.
- **Axe, on pickup**: `GameState.set_axe(true)` + `mark_used()` + hide the visual (no ghost prompt).
- **Return trigger**: a plain position check in `_process` (never a physics layer). Fires only when
  `GameState.wood_complete()` and only days 1–2, guarded by a once-only flag and `SceneTransition.is_busy()`.
- **Day 3 forest flow**: the spirit is present from scene start and blocks the left exit; the player is
  NOT required to cut any tree on day 3. `Spirit` is an `Interactable`; `interact()` →
  `SceneTransition.transition_to("res://scenes/ending.tscn")`.
- **HUD status string** (canonical): `"Dia %d/3 — Madeira %d/3"`.
- **Day 3 house**: child removed and a distinct empty-bed visual shown; the axe remains obtainable.

### Workflow note — regenerate the class cache before headless runs

`class_name` types (`Interactable`, `PlayerController`) resolve from `.godot/global_script_class_cache.cfg`,
which is gitignored and only rebuilt by the **editor**. After pulling new `class_name` scripts, run once:
```
& "<godot>" --headless --path "<project root>" --import
```
(prints `update_scripts_classes ... [ DONE ]`) before any headless scene run, otherwise you get
`Parse Error: Could not find base class "Interactable"`. Diagnostic probe: `res://tools/probe_ext.tscn`.

### Forest scene contract (builder-forest)
- Node `Forest` (Node2D) + `scripts/forest_loop.gd`.
- A `Player` instance (from `player.tscn`) present.
- 3 `tree.tscn` instances to the right; each adds exactly 1 wood once (use `one_shot = true`).
- When `GameState.wood_complete()` → switch to dusk (darker `CanvasModulate` or overlay) and reveal
  the return path.
- A return trigger on the left → day 1/2: `GameState.advance_day()` then
  `SceneTransition.transition_to("res://scenes/house_interior.tscn")`.
- Day 3 (`GameState.day == 3`): spawn `spirit.tscn`, block the return, and on spirit interaction →
  `SceneTransition.transition_to("res://scenes/ending.tscn")`.
- Day 2: at least one visible, solvable obstruction (e.g. `obstacle.tscn` — a fallen branch removed by
  one `interact`). No long puzzle.
- Call `HUD.set_status()` on `_ready()`/`day_changed`/`wood_changed`.

### House scene contract (builder-core)
- Node `HouseInterior` (Node2D) + `scripts/house_interior.gd`.
- `Player` instance, spawned near the door.
- `child.tscn` present **only when `GameState.child_present()`** (days 1-2); absent on day 3.
- Day 3 must show the empty bed/room detail (a distinct visual, e.g. dim empty bed + text via HUD).
- `axe.tscn` → on interact: `GameState.set_axe(true)`, then the node stops being interactable.
- `door.tscn` → only interactable when `GameState.has_axe`; then
  `SceneTransition.transition_to("res://scenes/forest.tscn")`.
- Call `HUD.set_status()`.

### Ending scene contract (builder-forest)
- Node `Ending` + `scripts/ending.gd`; final image/label, fade in, and `[E] reiniciar`.
- On `interact`: `GameState.reset()` then `SceneTransition.transition_to("res://scenes/house_interior.tscn")`.

---

## 7. Placeholders

Use `ColorRect` / `Polygon2D` / `Label` placeholders. Behaviour must **not** depend on exact sprite
sizes. No third-party asset may be added without registering it in `ASSETS_AND_AI.txt` (lead owns that file).

### 7.1 World conventions (fixed — do not invent a Camera2D)

- Viewport is **1280 x 720**. Levels are **single-screen**: everything must fit inside
  `x: 0..1280`, `y: 0..720`. **Do not add a Camera2D.**
- **Ground surface at `y = 600`.** Place a background `ColorRect` covering `0..1280 x 0..720` and a
  ground band `ColorRect` covering `0..1280 x 600..720` so the player has visual floor.
- Put the `Player` instance at `position = Vector2(x, 600)` (its origin is at the feet).
- Keep interactables within reach of the player: roughly `|Δx| <= 60` when standing next to them.

### 7.2 `.tscn` cheat-sheet (hand-written scenes)

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/forest_loop.gd" id="1_forest"]
[ext_resource type="PackedScene" path="res://scenes/player/player.tscn" id="2_player"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_wall"]
size = Vector2(40, 720)

[node name="Forest" type="Node2D"]
script = ExtResource("1_forest")

[node name="Player" parent="." instance=ExtResource("2_player")]
position = Vector2(160, 600)

[node name="WallRight" type="StaticBody2D" parent="."]
position = Vector2(1260, 360)

[node name="CollisionShape2D" type="CollisionShape2D" parent="WallRight"]
shape = SubResource("RectangleShape2D_wall")
```
- `load_steps` must be `>= (number of ext_resource + sub_resource) + 1`; when unsure, set it higher — Godot tolerates a larger value but not a smaller one.
- `groups=["interactable"]` goes in the `[node ...]` header.
- 1 unit = 1 pixel. `ColorRect` children of `Node2D` are positioned with `offset_left/top/right/bottom`.

## 8. Definition of done for any module

1. Parses with no errors (run `tools/validate_project.gd` plus a headless scene load).
2. Reachable in-game, not only correct by reading code.
3. Works after a scene reload / day change.
4. No regression in the flow above.
5. Report: result, files changed, evidence (exact command + output), risks.
