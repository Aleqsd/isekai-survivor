extends Node
class_name UtilsLib

## Utility helper script providing logging, randomness, and JSON persistence.
## All helpers are static so the script can be used via preload or class name.

const RARITY_COLORS: Dictionary = {
	"white": Color.WHITE,
	"green": Color(0.2, 0.8, 0.2),
	"blue": Color(0.2, 0.4, 1.0),
	"purple": Color(0.6, 0.2, 0.8),
	"orange": Color(1.0, 0.6, 0.0)
}

## Returns a color associated with a rarity string, falling back to white.
static func get_rarity_color(rarity: String) -> Color:
	if RARITY_COLORS.has(rarity):
		return RARITY_COLORS[rarity]
	return Color.WHITE

## Helper around Godot's logging that injects emoji and color-coded formatting.
static func log(color: String, emoji: String, message: String, payload: Variant = null) -> void:
	var display := "[color=%s]%s %s[/color]" % [color, emoji, message]
	if payload != null:
		print(display, " ", payload)
	else:
		print(display)

## Loads JSON from disk, returning default_value when the file is missing or invalid.
static func load_json(path: String, default_value: Variant) -> Variant:
	if not FileAccess.file_exists(path):
		UtilsLib.log("orange", "📄", "Missing file, returning default JSON", path)
		return default_value
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		UtilsLib.log("red", "💥", "Failed to open file for reading", path)
		return default_value
	var content := file.get_as_text()
	file.close()
	var data: Variant = JSON.parse_string(content)
	if typeof(data) == TYPE_NIL:
		UtilsLib.log("red", "💥", "JSON parse failed, returning default JSON", path)
		return default_value
	return data

## Saves JSON to disk while displaying vivid debug output in the console.
static func save_json(path: String, data: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		UtilsLib.log("red", "💥", "Failed to open file for writing", path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	UtilsLib.log("purple", "💾", "Persisted JSON data", path)

## Returns a random float within the provided bounds.
static func randf_range(min_value: float, max_value: float) -> float:
	return randf() * (max_value - min_value) + min_value

## Clamps a value between minimum and maximum thresholds.
static func clamp_value(value: float, min_value: float, max_value: float) -> float:
	return clampf(value, min_value, max_value)

## Picks a number of random items from a pool, guaranteeing unique selections.
static func pick_unique(pool: Array, count: int) -> Array:
	var copy := pool.duplicate()
	copy.shuffle()
	return copy.slice(0, min(count, copy.size()))
