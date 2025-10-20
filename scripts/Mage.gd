extends Player
class_name Mage

## Mage launches slower but powerful magic explosions.

@export var aoe_base_radius: float = 120.0

func _ready() -> void:
	super._ready()
	attack_cooldown = 1.6
	attack_power += 6.0
	attack_range = 280.0
	move_speed -= 10.0
	UtilsLib.log("purple", "✨", "Mage stats configured", {
		"aoe": aoe_base_radius,
		"attack_power": attack_power
	})

func perform_attack(target: Enemy) -> void:
	if game_manager == null:
		return
	var radius := aoe_base_radius * (1.0 + aoe_radius_percent * 0.01)
	var enemies_in_zone := game_manager.get_enemies_in_radius(target.global_position, radius)
	var damage := _calculate_damage()
	for enemy in enemies_in_zone:
		enemy.take_damage(damage)
	UtilsLib.log("purple", "🔥", "Mage blast exploded", {"targets": enemies_in_zone.size(), "damage": damage})
