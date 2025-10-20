extends Enemy
class_name Boss

## Boss enemies boast high stats and guaranteed equipment drops.

@export var equipment_pool: Array = []

func _ready() -> void:
	is_boss = true
	if max_hp < 300.0:
		max_hp = 300.0
	move_speed = 70.0
	contact_damage = 25.0
	attack_cooldown = 1.0
	xp_drop = 150
	super._ready()
	UtilsLib.log("purple", "👑", "Boss entered the battlefield", {
		"hp": max_hp,
		"xp_drop": xp_drop
	})

## Picks a random equipment item to drop on defeat.
func choose_drop() -> void:
	if equipment_pool.is_empty():
		return
	equipment_pool.shuffle()
	boss_drop_template = equipment_pool.front()
