extends Node
class_name EnemySpawner

## Responsible for dynamically spawning enemies and bosses over time.

signal enemy_spawned(enemy: Enemy)


@export var enemy_scenes: Array[PackedScene] = []
@export var boss_scene: PackedScene
@export var spawn_radius: float = 520.0
@export var spawn_rate: float = 1.8
@export var spawn_randomness: float = 0.4
@export var difficulty_ramp: float = 0.015
@export var boss_spawn_times: Array[float] = [120.0, 300.0, 600.0]
@export var boss_drop_table: Array = []

var game_manager: GameManager = null
var player: Player = null

var spawn_timer: float = 0.0
var elapsed_time: float = 0.0
var boss_index: int = 0

func _ready() -> void:
	player = get_tree().current_scene.get_node_or_null("Player")
	UtilsLib.log("green", "✅", "EnemySpawner ready", {
		"enemy_pools": enemy_scenes.size(),
		"boss_scene": boss_scene != null
	})

## Ticks spawn timers and ramps difficulty as minutes pass.
func _process(delta: float) -> void:
	if game_manager == null or player == null:
		if game_manager and game_manager.player:
			player = game_manager.player
		return
	if not game_manager.game_running:
		return
	elapsed_time += delta
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		var rate_multiplier: float = max(0.4, 1.0 - elapsed_time * difficulty_ramp)
		spawn_timer = max(0.4, spawn_rate * rate_multiplier + randf_range(-spawn_randomness, spawn_randomness))
	_check_boss_spawn()

## Spawns a normal enemy picked from the pool.
func _spawn_enemy() -> void:
	if enemy_scenes.is_empty():
		UtilsLib.log("red", "💥", "No enemy scenes configured")
		return
	var scene: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
	var enemy: Enemy = scene.instantiate()
	_add_enemy_to_scene(enemy)

## Handles the addition of an enemy to the current scene and sets dependencies.
func _add_enemy_to_scene(enemy: Enemy) -> void:
	var tree := get_tree()
	if tree.current_scene == null:
		return
	tree.current_scene.add_child(enemy)
	var spawn_position := _random_spawn_position()
	enemy.global_position = spawn_position
	enemy.target_player = player
	enemy.game_manager = game_manager
	emit_signal("enemy_spawned", enemy)
	UtilsLib.log("green", "✅", "Enemy spawned at position:", spawn_position)

## Checks timing to roll out bosses at pre-defined milestones.
func _check_boss_spawn() -> void:
	if boss_scene == null or boss_index >= boss_spawn_times.size():
		return
	if elapsed_time >= boss_spawn_times[boss_index]:
		_spawn_boss()
		boss_index += 1

## Instantiates a boss enemy and prepares its drop table.
func _spawn_boss() -> void:
	var boss: Boss = boss_scene.instantiate()
	boss.target_player = player
	boss.game_manager = game_manager
	if not boss_drop_table.is_empty():
		boss.equipment_pool = boss_drop_table.duplicate()
	if boss.has_method("choose_drop"):
		boss.choose_drop()
	_add_enemy_to_scene(boss)
	UtilsLib.log("purple", "👑", "Boss spawned onto the field")

## Picks a random position around the player within a radius.
func _random_spawn_position() -> Vector2:
	var angle := randf() * TAU
	var distance := spawn_radius + randf() * 120.0
	return player.global_position + Vector2.RIGHT.rotated(angle) * distance
