extends Node
class_name GameManager

## Orchestrates the high level game loop, connecting players, enemies, XP flow, and UI updates.

signal game_over

@export var player_path: NodePath
@export var enemy_spawner_path: NodePath
@export var ui_manager_path: NodePath
@export var level_up_ui_path: NodePath
@export var xp_gem_scene: PackedScene
@export var equipment_manager_path: NodePath


var player: Player = null
var enemy_spawner: EnemySpawner = null
var ui_manager: UIManager = null
var level_up_ui: LevelUpUI = null
var equipment_manager: EquipmentManagerData = null

var enemies: Array = []
var elapsed_time: float = 0.0
var game_running := true
var stat_upgrades: Array = []
var setup_complete := false

## On ready we collect node references, load stat upgrades, and prepare signals.
func _ready() -> void:
	randomize()
	_resolve_exports()
	UtilsLib.log("green", "✅", "GameManager ready", {
		"player": player != null,
		"spawner": enemy_spawner != null,
		"ui": ui_manager != null
	})

	_load_stat_upgrades()
	_finalize_setup()

## Allows runtime configuration from GameScene when nodes are spawned dynamically.
func configure(player_ref: Player, spawner_ref: EnemySpawner, ui_ref: UIManager, level_up_ref: LevelUpUI, equipment_ref: EquipmentManagerData) -> void:
	player = player_ref
	enemy_spawner = spawner_ref
	ui_manager = ui_ref
	level_up_ui = level_up_ref
	equipment_manager = equipment_ref
	_finalize_setup()

## Resolves exported NodePaths when scenes provide them.
func _resolve_exports() -> void:
	if player_path != NodePath(""):
		player = get_node_or_null(player_path)
	if enemy_spawner_path != NodePath(""):
		enemy_spawner = get_node_or_null(enemy_spawner_path)
	if ui_manager_path != NodePath(""):
		ui_manager = get_node_or_null(ui_manager_path)
	if level_up_ui_path != NodePath(""):
		level_up_ui = get_node_or_null(level_up_ui_path)
	if equipment_manager_path != NodePath(""):
		equipment_manager = get_node_or_null(equipment_manager_path) as EquipmentManagerData

## Finalises the wiring once the core references are available.
func _finalize_setup() -> void:
	if setup_complete:
		return
	if player == null or enemy_spawner == null or ui_manager == null or level_up_ui == null:
		return
	_connect_signals()
	_apply_equipment_bonus()
	enemy_spawner.game_manager = self
	enemy_spawner.player = player
	player.game_manager = self
	ui_manager.game_manager = self
	level_up_ui.hide_popup()
	ui_manager.update_health(player.current_hp, player.max_hp)
	ui_manager.update_xp(player.current_xp, player.xp_required, player.level)
	setup_complete = true

## Loads stat upgrade definitions from disk for later random selection.
func _load_stat_upgrades() -> void:
	var default_upgrades: Array = []
	var data: Variant = UtilsLib.load_json("res://data/stat_upgrades.json", default_upgrades)
	if typeof(data) == TYPE_ARRAY:
		stat_upgrades = data
	else:
		stat_upgrades = default_upgrades
	UtilsLib.log("yellow", "⚙️", "Loaded stat upgrades", stat_upgrades.size())

## Connects needed signals between the manager, player, and UI layers.
func _connect_signals() -> void:
	if player:
		player.connect("player_died", Callable(self, "_on_player_died"))
		player.connect("xp_threshold_reached", Callable(self, "_on_player_level_up"))
		player.connect("hp_changed", Callable(self, "_on_player_hp_changed"))
		player.connect("xp_changed", Callable(self, "_on_player_xp_changed"))
	if enemy_spawner:
		enemy_spawner.connect("enemy_spawned", Callable(self, "_on_enemy_spawned"))
	if level_up_ui:
		level_up_ui.connect("upgrade_chosen", Callable(self, "_on_upgrade_chosen"))

## Applies stat bonuses from equipped gear right at the run start.
func _apply_equipment_bonus() -> void:
	if equipment_manager == null or player == null:
		return
	var item := equipment_manager.get_equipped_item()
	if item.is_empty():
		UtilsLib.log("yellow", "🎯", "No equipment equipped, starting with base stats")
		return
	var stats: Dictionary = item.get("stats", {})
	for key in stats.keys():
		player.apply_equipment_stat(key, stats[key])
	var effects: Array = item.get("effects", [])
	UtilsLib.log("purple", "💎", "Applied equipment bonuses", {"name": item.get("name", ""), "effects": effects})

## Registers a freshly spawned enemy so that targeting and bookkeeping work correctly.
func register_enemy(enemy: Enemy) -> void:
	enemies.append(enemy)
	enemy.connect("enemy_died", Callable(self, "_on_enemy_died").bind(enemy))
	enemy.connect("deal_damage_to_player", Callable(self, "_on_enemy_hits_player"))
	UtilsLib.log("green", "✅", "Enemy registered", enemies.size())

## Removes enemy references when they leave play.
func unregister_enemy(enemy: Enemy) -> void:
	if enemies.has(enemy):
		enemies.erase(enemy)
		UtilsLib.log("orange", "🔥", "Enemy removed", enemies.size())

## Finds the closest enemy to a given point, optionally constrained by max distance.
func get_nearest_enemy(origin: Vector2, max_distance: float = INF) -> Enemy:
	var nearest: Enemy = null
	var best_dist := max_distance
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var d := origin.distance_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
			nearest = enemy
	return nearest

## Retrieves all enemies inside a search radius around a point.
func get_enemies_in_radius(origin: Vector2, radius: float) -> Array:
	var result := []
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if origin.distance_to(enemy.global_position) <= radius:
			result.append(enemy)
	return result

## Spawns an XP gem at the provided position that travels toward the player when magnetised.
func spawn_xp_gem(position: Vector2, amount: int) -> void:
	if xp_gem_scene == null:
		UtilsLib.log("red", "💥", "XP gem scene missing, cannot spawn drop")
		return
	var gem: XPGem = xp_gem_scene.instantiate()
	gem.amount = amount
	gem.player = player
	gem.game_manager = self
	get_tree().current_scene.add_child(gem)
	gem.global_position = position
	UtilsLib.log("green", "✅", "Spawned XP gem", {"amount": amount, "position": position})

## Adds XP to the player and refreshes UI.
func add_xp(amount: int) -> void:
	if player == null:
		return
	player.gain_xp(amount)

## Processes per-frame logic such as elapsed time tracking.
func _process(delta: float) -> void:
	if not game_running:
		return
	elapsed_time += delta
	if ui_manager:
		ui_manager.update_timer(elapsed_time)

## Handles player HP change to update UI.
func _on_player_hp_changed(current_hp: float, max_hp: float) -> void:
	if ui_manager:
		ui_manager.update_health(current_hp, max_hp)

## Handles player XP change to update UI.
func _on_player_xp_changed(current_xp: float, required_xp: float, level: int) -> void:
	if ui_manager:
		ui_manager.update_xp(current_xp, required_xp, level)

## Responds to XP threshold events triggered by the player.
func _on_player_level_up(level: int) -> void:
	if level_up_ui == null:
		return
	var options := UtilsLib.pick_unique(stat_upgrades, 3)
	get_tree().paused = true
	level_up_ui.show_options(options)
	UtilsLib.log("yellow", "⚔️", "Level up! Showing upgrade options", {"level": level})

## Applies the selected upgrade to the player and resumes gameplay.
func _on_upgrade_chosen(upgrade: Dictionary) -> void:
	get_tree().paused = false
	if player:
		player.apply_upgrade(upgrade)
	if ui_manager:
		ui_manager.display_upgrade_toast(upgrade.get("name", "Upgrade"))

## Handles enemy spawn notifications.
func _on_enemy_spawned(enemy: Enemy) -> void:
	register_enemy(enemy)

## When enemies die we unregister them and spawn XP.
func _on_enemy_died(xp_value: int, dropped_equipment: Dictionary, enemy: Enemy) -> void:
	unregister_enemy(enemy)
	if xp_value > 0:
		spawn_xp_gem(enemy.global_position, xp_value)
	if not dropped_equipment.is_empty() and equipment_manager:
		equipment_manager.add_item(dropped_equipment)
		if ui_manager:
			ui_manager.flash_equipment_drop(dropped_equipment)

## Enemies call this when they collide with the player for damage application.
func _on_enemy_hits_player(amount: float) -> void:
	if player:
		player.take_damage(amount)

## Deals with player death by halting the game and informing the UI/Game Over screen.
func _on_player_died() -> void:
	game_running = false
	get_tree().paused = true
	UtilsLib.log("red", "💀", "Player died, game over triggered")
	if ui_manager:
		ui_manager.show_game_over(elapsed_time, player.level)
	emit_signal("game_over")
