extends TileMap

## Builds a large, mostly open dungeon field using the imported Craftpix tiles.

const UtilsLib := preload("res://scripts/Utils.gd")


@export var map_radius: int = 120
@export var wall_margin: int = 8
var floor_sources: Array[int] = [0, 1, 2]
const FLOOR_COORD := Vector2i.ZERO
const WALL_SOURCE := 3
const WALL_COORD := Vector2i.ZERO
const FLOOR_VARIATION_CHANCE := 0.25
func _ready() -> void:
	await get_tree().process_frame
	randomize()
	clear()
	_build_floor()
	_build_walls()
	UtilsLib.log("green", "✅", "Dungeon tilemap generated", {
		"radius": map_radius,
		"wall_margin": wall_margin
	})

## Lays down the basic walkable area using the floor tiles.
func _build_floor() -> void:
	for x in range(-map_radius, map_radius):
		for y in range(-map_radius, map_radius):
			var source := floor_sources[0]
			if randf() < FLOOR_VARIATION_CHANCE:
				source = floor_sources[randi() % floor_sources.size()]
			set_cell(0, Vector2i(x, y), source, FLOOR_COORD)

## Places a soft boundary of wall tiles around the playable area.

func _build_walls() -> void:
	var outer := map_radius - 1
	for x in range(-outer, outer + 1):
		for y in range(-outer, outer + 1):
			var on_edge := x <= -outer + wall_margin or x >= outer - wall_margin or y <= -outer + wall_margin or y >= outer - wall_margin
			if on_edge:
				set_cell(0, Vector2i(x, y), WALL_SOURCE, WALL_COORD)
