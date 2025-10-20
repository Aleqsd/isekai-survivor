extends CharacterBody2D
class_name Player

## Base player controller handling movement, combat automation, and stat upgrades.

const UtilsLib := preload("res://scripts/Utils.gd")

signal player_died
signal xp_threshold_reached(level: int)
signal hp_changed(current_hp: float, max_hp: float)
signal xp_changed(current_xp: float, required_xp: float, level: int)

@export var move_speed: float = 180.0
@export var max_hp: float = 100.0
@export var attack_power: float = 12.0
@export var attack_cooldown: float = 1.4
@export var attack_range: float = 220.0
@export var loot_radius: float = 80.0

var current_hp: float = 100.0
var current_xp: float = 0.0
var level: int = 1
var xp_required: float = 50.0

var game_manager: GameManager = null

var attack_timer: float = 0.0
var regen_timer: float = 0.0

var attack_speed_bonus: float = 0.0
var cooldown_reduction_percent: float = 0.0
var attack_power_bonus_percent: float = 0.0
var flat_attack_bonus: float = 0.0
var move_speed_bonus_percent: float = 0.0
var move_speed_bonus_flat: float = 0.0
var loot_radius_percent: float = 0.0
var xp_gain_percent: float = 0.0
var crit_chance_percent: float = 5.0
var crit_damage_percent: float = 100.0
var duplicate_chance_percent: float = 0.0
var damage_reduction_percent: float = 0.0
var regen_per_second: float = 0.0
var attack_range_percent: float = 0.0
var aoe_radius_percent: float = 0.0

var animated_sprite: AnimatedSprite2D = null
var animation_state: StringName = ""
var is_attack_animation_active := false
var facing_vector: Vector2 = Vector2.DOWN
var attack_indicator: Polygon2D = null
var attack_indicator_timer: Timer = null
const ATTACK_INDICATOR_DURATION := 0.18
const ATTACK_INDICATOR_DISTANCE := 28.0

## Called when the node enters the scene tree for initialization.
func _ready() -> void:
	current_hp = max_hp
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		animated_sprite.animation_finished.connect(Callable(self, "_on_animation_finished"))
		_update_sprite_orientation()
	_create_attack_indicator()
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("xp_changed", current_xp, xp_required, level)
	UtilsLib.log("green", "✅", "Player ready with stats", {
		"hp": max_hp,
		"atk": attack_power,
		"cooldown": attack_cooldown
	})

## Physics process handles player movement and continuous auto-attacking.
func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_attack(delta)
	_process_regen(delta)

## Translates input to velocity and moves the character.
func _handle_movement(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * _get_move_speed()
	if velocity.length() > 0:
		velocity = velocity.normalized() * _get_move_speed()
		if input_vector.length() > 0.1:
			facing_vector = input_vector.normalized()
	move_and_slide()
	_update_movement_animation(input_vector)
	_update_sprite_orientation()

## Automatically seeks enemies and triggers attacks when cooldowns permit.
func _handle_attack(delta: float) -> void:
	if game_manager == null:
		return
	attack_timer -= delta
	if attack_timer > 0.0:
		return
	var target: Enemy = game_manager.get_nearest_enemy(global_position, _get_attack_range())
	if target == null:
		return
	if not is_instance_valid(target):
		return
	attack_timer = _get_attack_cooldown()
	_execute_attack(target)

## Applies any passive regeneration accumulated over time.
func _process_regen(delta: float) -> void:
	if regen_per_second <= 0.0 or current_hp <= 0.0 or current_hp >= max_hp:
		return
	regen_timer += delta
	if regen_timer >= 1.0:
		var ticks := int(regen_timer)
		regen_timer -= ticks
		var heal_amount := regen_per_second * ticks
		heal(heal_amount)

## Executes an attack, including potential duplicate attacks from upgrades.
func _execute_attack(target: Enemy) -> void:
	if target == null or not is_instance_valid(target):
		return
	var aim_direction := (target.global_position - global_position)
	if aim_direction.length() > 0.1:
		facing_vector = aim_direction.normalized()
		_update_sprite_orientation()
	_start_attack_animation()
	perform_attack(target)
	var duplicate_roll := randf() * 100.0
	if duplicate_roll < duplicate_chance_percent and is_instance_valid(target):
		UtilsLib.log("yellow", "🎯", "Duplicate strike triggered")
		perform_attack(target)

## Overridden in subclasses to provide class specific behaviours.
func perform_attack(target: Enemy) -> void:
	var damage := _calculate_damage()
	target.take_damage(damage)
	UtilsLib.log("yellow", "⚔️", "Base player strike landed", damage)

## Calculates the effective damage after bonuses and critical strikes.
func _calculate_damage() -> float:
	var base_damage := attack_power + flat_attack_bonus
	base_damage *= 1.0 + attack_power_bonus_percent * 0.01
	var crit_roll := randf() * 100.0
	if crit_roll < crit_chance_percent:
		var crit_multiplier := 1.0 + (crit_damage_percent * 0.01)
		UtilsLib.log("orange", "🔥", "Critical hit!", crit_multiplier)
		return base_damage * crit_multiplier
	return base_damage

## Retrieves the player's attack range including bonuses.
func _get_attack_range() -> float:
	return attack_range * (1.0 + attack_range_percent * 0.01)

## Computes effective movement speed with buffs.
func _get_move_speed() -> float:
	var speed := move_speed + move_speed_bonus_flat
	return speed * (1.0 + move_speed_bonus_percent * 0.01)

## Computes the distance at which XP gems are magnetised.
func get_loot_radius() -> float:
	return loot_radius * (1.0 + loot_radius_percent * 0.01)

## Determines the effective attack cooldown once bonuses apply.
func _get_attack_cooldown() -> float:
	var cooldown := attack_cooldown * (1.0 - attack_speed_bonus * 0.01)
	cooldown *= 1.0 - cooldown_reduction_percent * 0.01
	return max(cooldown, 0.15)

## Applies damage after mitigation and fires relevant signals.
func take_damage(amount: float) -> void:
	var mitigated: float = amount * (1.0 - clamp(damage_reduction_percent * 0.01, 0.0, 0.8))
	current_hp = max(current_hp - mitigated, 0.0)
	emit_signal("hp_changed", current_hp, max_hp)
	UtilsLib.log("red", "💥", "Player took damage", {"incoming": amount, "mitigated": mitigated, "hp": current_hp})
	if current_hp <= 0.0:
		emit_signal("player_died")

## Heals the player without exceeding the HP cap.
func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	current_hp = min(current_hp + amount, max_hp)
	emit_signal("hp_changed", current_hp, max_hp)
	UtilsLib.log("green", "✅", "Player healed", {"amount": amount, "hp": current_hp})

## Called when XP is picked up; handles thresholds and UI updates.
func gain_xp(amount: float) -> void:
	if amount <= 0.0:
		return
	var bonus := amount * (xp_gain_percent * 0.01)
	current_xp += amount + bonus
	emit_signal("xp_changed", current_xp, xp_required, level)
	UtilsLib.log("green", "✅", "XP collected", {"amount": amount, "bonus": bonus, "xp": current_xp})
	_check_level_up()

## Processes level ups by reducing XP and alerting the GameManager.
func _check_level_up() -> void:
	var leveled := false
	while current_xp >= xp_required:
		current_xp -= xp_required
		level += 1
		xp_required = ceil(xp_required * 1.25)
		leveled = true
	emit_signal("xp_changed", current_xp, xp_required, level)
	if leveled:
		emit_signal("xp_threshold_reached", level)

## Applies a chosen upgrade by its identifier.
func apply_upgrade(upgrade: Dictionary) -> void:
	var id: String = upgrade.get("id", "")
	match id:
		"atk_percent":
			attack_power_bonus_percent += 15.0
		"hp_percent":
			var ratio := current_hp / max_hp if max_hp > 0 else 1.0
			max_hp *= 1.20
			current_hp = max_hp * ratio
		"spd_percent":
			move_speed_bonus_percent += 12.0
		"loot_radius_percent":
			loot_radius_percent += 20.0
		"xp_gain_percent":
			xp_gain_percent += 15.0
		"attack_speed_percent":
			attack_speed_bonus += 12.0
		"crit_chance":
			crit_chance_percent += 5.0
		"crit_damage":
			crit_damage_percent += 30.0
		"attack_range":
			attack_range_percent += 12.0
		"cooldown_reduction":
			cooldown_reduction_percent += 8.0
		"aoe_radius":
			aoe_radius_percent += 18.0
		"life_regen":
			regen_per_second += 2.0
		"damage_reduction":
			damage_reduction_percent += 6.0
		"pickup_magnet":
			loot_radius_percent += 30.0
		"move_speed_flat":
			move_speed_bonus_flat += 20.0
		"bonus_xp_boss":
			xp_gain_percent += 10.0
		"duplicate_projectiles":
			duplicate_chance_percent = clamp(duplicate_chance_percent + 10.0, 0.0, 60.0)
		"flat_damage":
			flat_attack_bonus += 6.0
		"projectile_speed":
			attack_range_percent += 10.0
		"projectile_size":
			attack_power_bonus_percent += 8.0
		_:
			UtilsLib.log("orange", "⚙️", "Unhandled upgrade id", id)
	UtilsLib.log("green", "✅", "Applied upgrade", upgrade.get("name", id))

## Applies stat bonuses coming from equipped items prior to the run.
func apply_equipment_stat(stat_key: String, value) -> void:
	match stat_key:
		"atk":
			attack_power += float(value)
		"hp":
			var hp_ratio := current_hp / max_hp if max_hp > 0 else 1.0
			max_hp += float(value)
			current_hp = max_hp * hp_ratio
		"spd":
			move_speed_bonus_flat += float(value)
		"loot_radius":
			loot_radius += float(value)
		"crit":
			crit_chance_percent += float(value)
		_:
			UtilsLib.log("orange", "⚙️", "Unhandled equipment stat", stat_key)
	UtilsLib.log("purple", "💎", "Equipment stat applied", {"stat": stat_key, "value": value})

## Updates the movement animation based on current input direction unless an attack is playing.
func _update_movement_animation(input_vector: Vector2) -> void:
	if animated_sprite == null or is_attack_animation_active:
		return
	if input_vector.length() > 0.1:
		_play_animation("run")
	else:
		_play_animation("idle")

## Updates sprite orientation (flip / facing) based on the stored facing vector.
func _update_sprite_orientation() -> void:
	if animated_sprite == null:
		return
	var dir := facing_vector
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	animated_sprite.rotation = 0.0
	if abs(dir.x) > abs(dir.y):
		animated_sprite.flip_h = dir.x < 0
		animated_sprite.flip_v = false
	else:
		animated_sprite.flip_h = false
		animated_sprite.flip_v = dir.y < 0

## Plays the requested animation when available, avoiding unnecessary restarts unless forced.
func _play_animation(name: StringName, force := false) -> void:
	if animated_sprite == null:
		return
	var frames := animated_sprite.sprite_frames
	if frames == null or not frames.has_animation(name):
		return
	if not force and animation_state == name:
		return
	animation_state = name
	animated_sprite.play(name)

## Starts the attack animation and flags the state so movement animations pause.
func _start_attack_animation() -> void:
	if animated_sprite == null:
		return
	var frames := animated_sprite.sprite_frames
	if frames == null or not frames.has_animation("attack"):
		return
	is_attack_animation_active = true
	_update_sprite_orientation()
	_show_attack_indicator()
	_play_animation("attack", true)

## Resets after an attack animation finishes so movement can resume animating.
func _on_animation_finished(anim_name: StringName = &"") -> void:
	if anim_name == "attack":
		is_attack_animation_active = false
		_update_movement_animation(velocity)

func _create_attack_indicator() -> void:
	attack_indicator = Polygon2D.new()
	attack_indicator.color = Color(1.0, 0.85, 0.3, 0.55)
	attack_indicator.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(14, -6),
		Vector2(14, 6)
	])
	attack_indicator.visible = false
	attack_indicator.z_index = 10
	add_child(attack_indicator)
	attack_indicator_timer = Timer.new()
	attack_indicator_timer.one_shot = true
	attack_indicator_timer.wait_time = ATTACK_INDICATOR_DURATION
	add_child(attack_indicator_timer)
	attack_indicator_timer.timeout.connect(Callable(self, "_on_attack_indicator_timeout"))

func _show_attack_indicator() -> void:
	if attack_indicator == null:
		return
	var dir := facing_vector
	if dir.length() <= 0.01:
		dir = Vector2.DOWN
	attack_indicator.visible = true
	attack_indicator.position = dir.normalized() * ATTACK_INDICATOR_DISTANCE
	attack_indicator.rotation = dir.angle()
	attack_indicator_timer.start()

func _on_attack_indicator_timeout() -> void:
	if attack_indicator:
		attack_indicator.visible = false
