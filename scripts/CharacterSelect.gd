extends Control

## Handles hero selection before starting a run.


const UtilsLib := preload("res://scripts/Utils.gd")

@onready var archer_button: Button = $Panel/VBox/HeroButtons/ArcherButton
@onready var mage_button: Button = $Panel/VBox/HeroButtons/MageButton
@onready var warrior_button: Button = $Panel/VBox/HeroButtons/WarriorButton
@onready var back_button: Button = $Panel/VBox/BackButton

func _ready() -> void:
	archer_button.pressed.connect(Callable(self, "_on_archer_pressed"))
	mage_button.pressed.connect(Callable(self, "_on_mage_pressed"))
	warrior_button.pressed.connect(Callable(self, "_on_warrior_pressed"))
	back_button.pressed.connect(Callable(self, "_on_back_pressed"))
	UtilsLib.log("green", "✅", "Character select menu ready")

func _start_run(scene_path: String) -> void:
## Stores the chosen character and transitions into the gameplay scene.
	get_tree().set_meta("selected_character_scene", scene_path)
	get_tree().change_scene_to_file("res://GameScene.tscn")
	UtilsLib.log("yellow", "🎯", "Starting run with hero", scene_path)

func _on_archer_pressed() -> void:
	_start_run("res://actors/Archer.tscn")

func _on_mage_pressed() -> void:
	_start_run("res://actors/Mage.tscn")

func _on_warrior_pressed() -> void:
	_start_run("res://actors/Warrior.tscn")

func _on_back_pressed() -> void:
## Returns to the main menu when the player backs out.
	get_tree().change_scene_to_file("res://MainMenu.tscn")
