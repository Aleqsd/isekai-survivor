extends Area2D
class_name XPGem

## Collectible XP gem that drifts towards the player when within loot radius.


@export var amount: int = 5
@export var magnet_speed: float = 320.0

var player: Player = null
var game_manager: GameManager = null

func _ready() -> void:
	UtilsLib.log("green", "✅", "XP gem spawned", {"amount": amount})

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var distance := global_position.distance_to(player.global_position)
	if distance <= player.get_loot_radius():
		var direction := (player.global_position - global_position).normalized()
		global_position += direction * magnet_speed * delta
		if distance <= 12.0:
			_collect()

## Applies XP to the player through the GameManager.
func _collect() -> void:
	if game_manager:
		game_manager.add_xp(amount)
	UtilsLib.log("green", "💎", "XP gem collected", amount)
	queue_free()
