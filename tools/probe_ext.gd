extends Interactable
## Lead-owned probe: verifies that `class_name Interactable` resolves in a
## headless (non-editor) run. If this fails, builders must use path-based extends.

func _ready() -> void:
	print("PROBE_EXTENDS_INTERACTABLE_OK")
	get_tree().quit(0)
