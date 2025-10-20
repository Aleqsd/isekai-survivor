extends CanvasLayer
class_name LevelUpUI

## Display for level up selections offering three stat upgrades.

signal upgrade_chosen(upgrade: Dictionary)


@onready var option_buttons := [
	$Panel/VBoxContainer/Option1,
	$Panel/VBoxContainer/Option2,
	$Panel/VBoxContainer/Option3
]

var current_options: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide_popup()
	for button in option_buttons:
		button.pressed.connect(Callable(self, "_on_option_pressed").bind(button))

## Populates the popup with new upgrade options and reveals it.
func show_options(options: Array) -> void:
	current_options = options
	for i in option_buttons.size():
		var button: Button = option_buttons[i]
		if i < current_options.size():
			var upgrade: Dictionary = current_options[i]
			button.text = "[%s] %s" % [upgrade.get("name", "Upgrade"), upgrade.get("description", "")]
			button.disabled = false
		else:
			button.text = "No Option"
			button.disabled = true
	visible = true
	UtilsLib.log("yellow", "⚔️", "Level Up! Choose your upgrade!")

## Conceals the popup and clears button text.
func hide_popup() -> void:
	visible = false
	for button in option_buttons:
		button.text = ""
		button.disabled = true

## Handles button selection and forwards the chosen upgrade.
func _on_option_pressed(button: Button) -> void:
	var index := option_buttons.find(button)
	if index == -1 or index >= current_options.size():
		return
	var upgrade: Dictionary = current_options[index]
	hide_popup()
	emit_signal("upgrade_chosen", upgrade)
	UtilsLib.log("green", "✅", "Upgrade chosen", upgrade.get("name", ""))
