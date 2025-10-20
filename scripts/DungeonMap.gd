extends TileMap

## Builds a large, mostly open dungeon field using the imported Craftpix tiles.


@export var map_radius: int = 150
@export var wall_margin: int = 6
@export var floor_source_id: int = 0
@export var floor_atlas_coord: Vector2i = Vector2i.ZERO
@export var wall_source_id: int = 1
@export var wall_atlas_coord: Vector2i = Vector2i.ZERO
func _ready() -> void:
	await get_tree().process_frame
	clear()
	_build_floor()
	_build_walls()
	UtilsLib.log("green", "✅", "Dungeon tilemap generated", {
		"radius": map_radius,
		"wall_margin": wall_margin
	})

## Lays down the basic walkable area using the floor tile.
func _build_floor() -> void:
	for x in range(-map_radius, map_radius):
		for y in range(-map_radius, map_radius):
			set_cell(0, Vector2i(x, y), floor_source_id, floor_atlas_coord)

## Places a soft boundary of wall tiles around the playable area.
func _build_walls() -> void:
	var outer := map_radius - 1
	for x in range(-outer, outer + 1):
		for y in range(-outer, outer + 1):
			var on_edge := x <= -outer + wall_margin or x >= outer - wall_margin or y <= -outer + wall_margin or y >= outer - wall_margin
			if on_edge:
				set_cell(0, Vector2i(x, y), wall_source_id, wall_atlas_coord)
