extends Control

## Displays end-of-run statistics and allows retrying or returning to the main menu.

const UtilsLib := preload("res://scripts/Utils.gd")


@onready var summary_label: Label = $GameOverUI/VBoxContainer/SummaryLabel
@onready var retry_button: Button = $GameOverUI/VBoxContainer/RetryButton
@onready var main_menu_button: Button = $GameOverUI/VBoxContainer/MainMenuButton

func _ready() -> void:
	get_tree().paused = false
	retry_button.pressed.connect(Callable(self, "_on_retry_pressed"))
	main_menu_button.pressed.connect(Callable(self, "_on_main_menu_pressed"))
	_display_summary()
	UtilsLib.log("yellow", "⚙️", "Game over screen ready")

## Fetches run data stored by the UIManager and updates the UI.
func _display_summary() -> void:
	var data := {"duration": 0.0, "level": 1}
	if get_tree().has_meta("game_over_data"):
		var meta_data = get_tree().get_meta("game_over_data")
		if typeof(meta_data) == TYPE_DICTIONARY:
			data = meta_data
	var duration: float = data.get("duration", 0.0)
	var level: int = data.get("level", 1)
	var minutes := int(duration) / 60
	var seconds := int(duration) % 60
	summary_label.text = "Fallen at %02d:%02d — Level %d" % [minutes, seconds, level]
	UtilsLib.log("purple", "💀", "Displaying game over summary", data)

func _on_retry_pressed() -> void:
	var scene_path := "res://actors/Archer.tscn"
	if get_tree().has_meta("selected_character_scene"):
		scene_path = String(get_tree().get_meta("selected_character_scene"))
	get_tree().set_meta("selected_character_scene", scene_path)
	get_tree().set_meta("game_over_data", {})
	get_tree().change_scene_to_file("res://GameScene.tscn")
	UtilsLib.log("green", "✅", "Retrying run from game over screen")

func _on_main_menu_pressed() -> void:
	get_tree().set_meta("game_over_data", {})
	get_tree().change_scene_to_file("res://MainMenu.tscn")
	UtilsLib.log("yellow", "🎯", "Returning to main menu from game over screen")
