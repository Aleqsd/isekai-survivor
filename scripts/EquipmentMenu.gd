extends Control
class_name EquipmentMenu

## Presents owned equipment and allows choosing one item before a run.

signal menu_closed


@onready var item_list: ItemList = $Panel/VBoxContainer/ItemList
@onready var equip_button: Button = $Panel/VBoxContainer/HBoxContainer/EquipButton
@onready var close_button: Button = $Panel/VBoxContainer/HBoxContainer/CloseButton

var equipment_manager: EquipmentManagerData = null

func _ready() -> void:
	visible = false
	equip_button.pressed.connect(Callable(self, "_on_equip_pressed"))
	close_button.pressed.connect(Callable(self, "_on_close_pressed"))

## Injects the EquipmentManager dependency and refreshes the UI.
func set_equipment_manager(manager: EquipmentManagerData) -> void:
	equipment_manager = manager
	if equipment_manager:
		equipment_manager.connect("equipment_updated", Callable(self, "_on_equipment_updated"))
	refresh_items()

## Rebuilds the list with the current owned items.
func refresh_items() -> void:
	item_list.clear()
	if equipment_manager == null:
		return
	for item in equipment_manager.owned_items:
		var item_name: String = item.get("name", "Relic")
		var rarity_label: String = item.get("rarity", "white")
		var list_index: int = item_list.add_item("%s (%s)" % [item_name, rarity_label.capitalize()])
		item_list.set_item_metadata(list_index, item)
		item_list.set_item_custom_fg_color(list_index, UtilsLib.get_rarity_color(rarity_label))
		if equipment_manager.equipped_item == item_name:
			item_list.select(list_index)

## Opens the menu by making it visible.
func open_menu() -> void:
	refresh_items()
	visible = true
	UtilsLib.log("purple", "💎", "Equipment menu opened")

## Hides the menu ensuring clean state.
func close_menu() -> void:
	visible = false
	emit_signal("menu_closed")
	UtilsLib.log("yellow", "🎯", "Equipment menu closed")

func _on_equipment_updated(_owned_items: Array, _equipped_item: String) -> void:
	refresh_items()

func _on_equip_pressed() -> void:
	if equipment_manager == null:
		return
	var selected := item_list.get_selected_items()
	if selected.is_empty():
		return
	var item: Dictionary = item_list.get_item_metadata(selected[0])
	equipment_manager.equip_item(item.get("name", ""))
	refresh_items()
	UtilsLib.log("green", "✅", "Equipped item via menu", item.get("name", ""))

func _on_close_pressed() -> void:
## Closes the menu when the player taps the close button.
	close_menu()
