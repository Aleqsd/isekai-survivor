extends Control

## Main menu controller handling navigation and equipment access.

const UtilsLib := preload("res://scripts/Utils.gd")
const EquipmentMenuScene := preload("res://ui/EquipmentMenu.tscn")

@onready var start_button: Button = $CenterPanel/VBox/Buttons/StartButton
@onready var equipment_button: Button = $CenterPanel/VBox/Buttons/EquipmentButton
@onready var quit_button: Button = $CenterPanel/VBox/Buttons/QuitButton

var equipment_menu: EquipmentMenu = null

func _ready() -> void:
	start_button.pressed.connect(Callable(self, "_on_start_pressed"))
	equipment_button.pressed.connect(Callable(self, "_on_equipment_pressed"))
	quit_button.pressed.connect(Callable(self, "_on_quit_pressed"))
	UtilsLib.log("green", "✅", "Main menu ready")

func _on_start_pressed() -> void:
## Starts the game by loading the character selection scene.
	get_tree().change_scene_to_file("res://CharacterSelect.tscn")
	UtilsLib.log("yellow", "🎯", "Navigating to character selection")

func _on_equipment_pressed() -> void:
## Opens the equipment management popup.
	if equipment_menu == null:
		equipment_menu = EquipmentMenuScene.instantiate()
		add_child(equipment_menu)
		var manager := get_node_or_null("/root/EquipmentManager") as EquipmentManagerData
		if manager:
			equipment_menu.set_equipment_manager(manager)
	if equipment_menu:
		equipment_menu.open_menu()

func _on_quit_pressed() -> void:
## Exits the application from the menu.
	get_tree().quit()
	UtilsLib.log("red", "💥", "Quit requested from main menu")
