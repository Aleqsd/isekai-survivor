extends CharacterBody2D
class_name Enemy

## Generic enemy behaviour including navigation toward the player and death handling.

signal enemy_died(xp_value: int, dropped_equipment: Dictionary)
signal deal_damage_to_player(amount: float)


@export var max_hp: float = 30.0
@export var move_speed: float = 90.0
@export var contact_damage: float = 10.0
@export var xp_drop: int = 5
@export var attack_cooldown: float = 1.2
@export var animation_base_path: String = ""

var current_hp: float = 30.0
var target_player: Player = null
var game_manager: GameManager = null
var attack_timer: float = 0.0

var is_boss := false
var boss_drop_template: Dictionary = {}
var animated_sprite: AnimatedSprite2D = null
var animation_state: StringName = ""
var is_attack_animation_active := false

func _ready() -> void:
	current_hp = max_hp
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	_setup_sprite_frames()
	if animated_sprite:
		animated_sprite.animation_finished.connect(Callable(self, "_on_animation_finished"))
		_play_animation("idle", true)
	UtilsLib.log("green", "✅", "Enemy spawned", {
		"hp": max_hp,
		"speed": move_speed,
		"boss": is_boss
	})

## Handles navigation and attack cadence.
func _physics_process(delta: float) -> void:
	if target_player == null or not is_instance_valid(target_player):
		return
	var direction := (target_player.global_position - global_position)
	if direction.length() > 0:
		direction = direction.normalized()
	velocity = direction * move_speed
	move_and_slide()
	_update_movement_animation()

	attack_timer -= delta
	if attack_timer <= 0.0 and global_position.distance_to(target_player.global_position) < 32.0:
		attack_timer = attack_cooldown
		_start_attack_animation()
		emit_signal("deal_damage_to_player", contact_damage)
		UtilsLib.log("red", "💥", "Enemy damaged player", contact_damage)

## Applies incoming damage and handles death logic.
func take_damage(amount: float) -> void:
	current_hp -= amount
	UtilsLib.log("orange", "💥", "Enemy took damage", {"amount": amount, "hp": current_hp})
	if current_hp <= 0.0:
		_die()

## Called upon health reaching zero; emits drop info and frees the instance.
func _die() -> void:
	var drop := {}
	if is_boss and not boss_drop_template.is_empty():
		drop = boss_drop_template
	UtilsLib.log("green", "✅", "Enemy defeated", {"xp": xp_drop, "equipment": drop})
	emit_signal("enemy_died", xp_drop, drop)
	queue_free()

## Generates sprite frames dynamically from the provided asset directory.
func _setup_sprite_frames() -> void:
	if animated_sprite == null or animation_base_path == "":
		return
	var frames := SpriteFrames.new()
	_add_animation(frames, "idle", "%s/idle" % animation_base_path, 6.0, true)
	_add_animation(frames, "run", "%s/run" % animation_base_path, 8.0, true)
	_add_animation(frames, "attack", "%s/attack" % animation_base_path, 12.0, false)
	if frames.get_animation_names().is_empty():
		return
	animated_sprite.sprite_frames = frames
	animated_sprite.play(frames.get_animation_names()[0])

## Registers an animation sequence inside the sprite frames resource.
func _add_animation(frames: SpriteFrames, name: String, path: String, speed: float, loop: bool) -> void:
	var textures := _load_textures_from(path)
	if textures.is_empty():
		return
	frames.add_animation(name)
	frames.set_animation_loop(name, loop)
	frames.set_animation_speed(name, speed)
	for tex in textures:
		frames.add_frame(name, tex)

## Loads textures from a directory, sorted to maintain frame order.
func _load_textures_from(path: String) -> Array:
	var textures: Array = []
	var dir := DirAccess.open(path)
	if dir == null:
		return textures
	var files: Array = []
	dir.list_dir_begin()
	while true:
		var file := dir.get_next()
		if file == "":
			break
		if dir.current_is_dir():
			continue
		if file.to_lower().ends_with(".png"):
			files.append(file)
	dir.list_dir_end()
	files.sort()
	for file in files:
		var tex: Texture2D = load("%s/%s" % [path, file])
		if tex:
			textures.append(tex)
	return textures

## Keeps the movement animation in sync with velocity while not attacking.
func _update_movement_animation() -> void:
	if animated_sprite == null or is_attack_animation_active:
		return
	if velocity.length() > 5.0:
		_play_animation("run")
	else:
		_play_animation("idle")

## Plays the requested animation when available.
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

## Plays the attack animation and pauses movement updates while it runs.
func _start_attack_animation() -> void:
	if animated_sprite == null:
		return
	var frames := animated_sprite.sprite_frames
	if frames == null or not frames.has_animation("attack"):
		return
	is_attack_animation_active = true
	_play_animation("attack", true)

## Callback for animation completion so we can resume movement cycles.
func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack":
		is_attack_animation_active = false
		_update_movement_animation()
