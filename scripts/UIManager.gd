extends CanvasLayer
class_name UIManager

## Manages HUD updates, popups, and feedback messaging.

const UtilsLib := preload("res://scripts/Utils.gd")


@onready var health_bar: ProgressBar = $Control/HUDBackground/HUDVBox/HealthBar
@onready var health_label: Label = $Control/HUDBackground/HUDVBox/HealthLabel
@onready var xp_bar: ProgressBar = $Control/HUDBackground/HUDVBox/XPBar
@onready var xp_label: Label = $Control/HUDBackground/HUDVBox/XPLabel
@onready var timer_label: Label = $Control/HUDBackground/HUDVBox/TimerLabel
@onready var toast_label: Label = $Control/ToastLabel
@onready var toast_timer: Timer = $Control/ToastTimer
@onready var equipment_label: Label = $Control/EquipmentLabel
var game_manager: GameManager = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if is_instance_valid(toast_label):
		toast_label.visible = false
	if is_instance_valid(toast_timer):
		toast_timer.timeout.connect(Callable(self, "_on_toast_timeout"))

## Updates health related UI elements.
func update_health(current_hp: float, max_hp: float) -> void:
	if not is_instance_valid(health_bar):
		health_bar = get_node_or_null("Control/HUDBackground/HUDVBox/HealthBar") as ProgressBar
		health_label = get_node_or_null("Control/HUDBackground/HUDVBox/HealthLabel") as Label
	if not is_instance_valid(health_bar) or not is_instance_valid(health_label):
		return
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	health_label.text = "HP: %.0f / %.0f" % [current_hp, max_hp]

## Updates experience progress.
func update_xp(current_xp: float, required_xp: float, level: int) -> void:
	if not is_instance_valid(xp_bar):
		xp_bar = get_node_or_null("Control/HUDBackground/HUDVBox/XPBar") as ProgressBar
		xp_label = get_node_or_null("Control/HUDBackground/HUDVBox/XPLabel") as Label
	if not is_instance_valid(xp_bar) or not is_instance_valid(xp_label):
		return
	xp_bar.max_value = required_xp
	xp_bar.value = current_xp
	xp_label.text = "Level %d — XP %.0f / %.0f" % [level, current_xp, required_xp]

## Displays the run timer in m:ss format.
func update_timer(seconds: float) -> void:
	if not is_instance_valid(timer_label):
		timer_label = get_node_or_null("Control/HUDBackground/HUDVBox/TimerLabel") as Label
	if not is_instance_valid(timer_label):
		return
	var minutes := int(seconds) / 60
	var secs := int(seconds) % 60
	timer_label.text = "Time %02d:%02d" % [minutes, secs]

## Shows a quick toast message for upgrade confirmation.
func display_upgrade_toast(text: String) -> void:
	if not is_instance_valid(toast_label):
		toast_label = get_node_or_null("Control/ToastLabel") as Label
		toast_timer = get_node_or_null("Control/ToastTimer") as Timer
	if not is_instance_valid(toast_label) or not is_instance_valid(toast_timer):
		return
	toast_label.text = "⭐ %s" % text
	toast_label.visible = true
	toast_timer.start(2.0)
	UtilsLib.log("green", "✅", "Upgrade toast displayed", text)

## Displays equipment drop feedback.
func flash_equipment_drop(equipment: Dictionary) -> void:
	if not is_instance_valid(equipment_label):
		equipment_label = get_node_or_null("Control/EquipmentLabel") as Label
	if not is_instance_valid(equipment_label):
		return
	var rarity: String = equipment.get("rarity", "white")
	var color: Color = UtilsLib.get_rarity_color(rarity)
	equipment_label.modulate = color
	equipment_label.text = "Loot: %s (%s)" % [equipment.get("name", "Mystery Item"), rarity.capitalize()]
	UtilsLib.log("purple", "💎", "Equipment drop announced", equipment)

## Transitions to the dedicated game over scene summarising the run.
func show_game_over(duration: float, level: int) -> void:
	var data := {
		"duration": duration,
		"level": level
	}
	get_tree().paused = false
	get_tree().set_meta("game_over_data", data)
	get_tree().change_scene_to_file("res://GameOver.tscn")
	UtilsLib.log("red", "💀", "Game over scene triggered", data)

func _on_toast_timeout() -> void:
	if is_instance_valid(toast_label):
		toast_label.visible = false
