extends Player
class_name Warrior

## Warrior focuses on close range sweeping attacks and resilience.

@export var slash_radius: float = 90.0

func _ready() -> void:
	super._ready()
	_setup_sprite_frames()
	attack_cooldown = 0.9
	attack_power += 4.0
	max_hp += 30.0
	current_hp = max_hp
	attack_range = 180.0
	move_speed += 5.0
	UtilsLib.log("red", "⚔️", "Warrior stats configured", {
		"slash_radius": slash_radius,
		"hp": max_hp
	})
	_play_animation("idle", true)

func perform_attack(target: Enemy) -> void:
	if game_manager == null:
		return
	var enemies := game_manager.get_enemies_in_radius(global_position, slash_radius * (1.0 + aoe_radius_percent * 0.01))
	var damage := _calculate_damage()
	for enemy in enemies:
		enemy.take_damage(damage)
	UtilsLib.log("red", "🔥", "Warrior slash executed", {"targets": enemies.size(), "damage": damage})

func _setup_sprite_frames() -> void:
	if animated_sprite == null:
		return
	var frames := SpriteFrames.new()
	_add_animation(frames, "idle", "res://assets/player/warrior/idle", 10.0, true)
	_add_animation(frames, "run", "res://assets/player/warrior/run", 12.0, true)
	_add_animation(frames, "attack", "res://assets/player/warrior/attack", 14.0, false)
	if frames.get_animation_names().is_empty():
		return
	animated_sprite.sprite_frames = frames
	animated_sprite.play("idle")

## Configures a single animation within the sprite frames resource.
func _add_animation(frames: SpriteFrames, name: String, path: String, speed: float, loop: bool) -> void:
	var textures := _load_textures_from(path)
	if textures.is_empty():
		UtilsLib.log("orange", "⚙️", "Missing animation frames", {"name": name, "path": path})
		return
	frames.add_animation(name)
	frames.set_animation_loop(name, loop)
	frames.set_animation_speed(name, speed)
	for tex in textures:
		frames.add_frame(name, tex)

## Loads texture frames from disk for a named animation.
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
