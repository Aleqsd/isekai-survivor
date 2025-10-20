extends Player
class_name Archer

## Archer specialises in rapid ranged attacks with limited piercing.

@export var pierce_count: int = 1

func _ready() -> void:
	super._ready()
	attack_cooldown = 1.0
	attack_range = 320.0
	move_speed += 10.0
	UtilsLib.log("yellow", "🎯", "Archer stats configured", {
		"pierce": pierce_count,
		"range": attack_range
	})

func perform_attack(target: Enemy) -> void:
	if game_manager == null:
		return
	var damage := _calculate_damage()
	target.take_damage(damage)
	UtilsLib.log("yellow", "⚔️", "Archer arrow hit target", damage)
	var remaining := pierce_count
	if remaining <= 0:
		return
	var splash_radius := 72.0 * (1.0 + aoe_radius_percent * 0.01)
	var others := game_manager.get_enemies_in_radius(target.global_position, splash_radius)
	for enemy in others:
		if enemy == target:
			continue
		if remaining <= 0:
			break
		enemy.take_damage(damage * 0.6)
		remaining -= 1
		UtilsLib.log("yellow", "🎯", "Archer pierce dealt bonus damage", enemy.name)
