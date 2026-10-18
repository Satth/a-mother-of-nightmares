extends Node
## Central persistent state for the three-day loop.
## Owner: lead. Interface frozen in CONTRACT.md §2 — do not change without asking.

signal day_changed(day: int)
signal wood_changed(wood: int, target: int)
signal axe_changed(has_axe: bool)

const WOOD_TARGET := 3
const MAX_DAY := 3

var day: int = 1
var wood: int = 0
var has_axe: bool = false


func reset() -> void:
	day = 1
	wood = 0
	has_axe = false
	day_changed.emit(day)
	wood_changed.emit(wood, WOOD_TARGET)
	axe_changed.emit(has_axe)


func set_axe(value: bool = true) -> void:
	if has_axe == value:
		return
	has_axe = value
	axe_changed.emit(has_axe)


## Adds wood and returns how many units were actually counted (never over the target).
func add_wood(amount: int = 1) -> int:
	var before := wood
	wood = clampi(wood + amount, 0, WOOD_TARGET)
	if wood != before:
		wood_changed.emit(wood, WOOD_TARGET)
	return wood - before


func wood_complete() -> bool:
	return wood >= WOOD_TARGET


func child_present() -> bool:
	return day <= 2


## Advances exactly one day (capped at MAX_DAY) and resets per-day progress.
func advance_day() -> void:
	if day >= MAX_DAY:
		return
	day += 1
	wood = 0
	has_axe = false
	wood_changed.emit(wood, WOOD_TARGET)
	axe_changed.emit(has_axe)
	day_changed.emit(day)
