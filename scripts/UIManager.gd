extends CanvasLayer
class_name UIManager

## Manages HUD updates, popups, and feedback messaging.


@onready var health_bar: ProgressBar = $HUDBackground/HUDVBox/HealthBar
@onready var health_label: Label = $HUDBackground/HUDVBox/HealthLabel
@onready var xp_bar: ProgressBar = $HUDBackground/HUDVBox/XPBar
@onready var xp_label: Label = $HUDBackground/HUDVBox/XPLabel
@onready var timer_label: Label = $HUDBackground/HUDVBox/TimerLabel
@onready var toast_label: Label = $ToastLabel
@onready var toast_timer: Timer = $ToastTimer
@onready var equipment_label: Label = $EquipmentLabel
var game_manager: GameManager = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	toast_label.visible = false
	toast_timer.timeout.connect(Callable(self, "_on_toast_timeout"))

## Updates health related UI elements.
func update_health(current_hp: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current_hp
	health_label.text = "HP: %.0f / %.0f" % [current_hp, max_hp]

## Updates experience progress.
func update_xp(current_xp: float, required_xp: float, level: int) -> void:
	xp_bar.max_value = required_xp
	xp_bar.value = current_xp
	xp_label.text = "Level %d — XP %.0f / %.0f" % [level, current_xp, required_xp]

## Displays the run timer in m:ss format.
func update_timer(seconds: float) -> void:
	var minutes := int(seconds) / 60
	var secs := int(seconds) % 60
	timer_label.text = "Time %02d:%02d" % [minutes, secs]

## Shows a quick toast message for upgrade confirmation.
func display_upgrade_toast(text: String) -> void:
	toast_label.text = "⭐ %s" % text
	toast_label.visible = true
	toast_timer.start(2.0)
	UtilsLib.log("green", "✅", "Upgrade toast displayed", text)

## Displays equipment drop feedback.
func flash_equipment_drop(equipment: Dictionary) -> void:
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
	toast_label.visible = false
