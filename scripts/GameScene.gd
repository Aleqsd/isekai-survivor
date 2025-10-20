extends Node2D

## High-level scene controller that spawns the selected hero and wires systems together.


@onready var player_root: Node2D = $PlayerRoot
@onready var game_manager: GameManager = $GameManager
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var ui_manager: UIManager = $UIManager
@onready var level_up_ui: LevelUpUI = $LevelUpUI

var player: Player = null
var camera: Camera2D = null

func _ready() -> void:
	get_tree().paused = false
	_spawn_player()
	_wire_systems()

## Spawns the hero the player selected in the character selection scene.
func _spawn_player() -> void:
	var scene_path := "res://actors/Archer.tscn"
	if get_tree().has_meta("selected_character_scene"):
		scene_path = String(get_tree().get_meta("selected_character_scene"))
	var character_scene: PackedScene = load(scene_path)
	if character_scene == null:
		UtilsLib.log("red", "💥", "Failed to load character scene, defaulting to Archer", scene_path)
		character_scene = load("res://actors/Archer.tscn")
	player = character_scene.instantiate()
	player.name = "Player"
	player_root.add_child(player)
	get_tree().set_meta("selected_character_scene", scene_path)
	camera = Camera2D.new()
	camera.position = Vector2.ZERO
	camera.offset = Vector2.ZERO
	camera.limit_left = -2000
	camera.limit_right = 2000
	camera.limit_top = -2000
	camera.limit_bottom = 2000
	player.add_child(camera)
	camera.make_current()
	UtilsLib.log("green", "✅", "Player spawned in GameScene", scene_path)

## Connects dependencies across gameplay systems once the player exists.
func _wire_systems() -> void:
	var equipment_manager := get_node_or_null("/root/EquipmentManager")
	game_manager.configure(player, enemy_spawner, ui_manager, level_up_ui, equipment_manager as EquipmentManagerData)
	if enemy_spawner:
		enemy_spawner.player = player
	UtilsLib.log("yellow", "⚙️", "Game scene wiring complete")
