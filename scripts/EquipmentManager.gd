extends Node
class_name EquipmentManagerData

## Handles persistence and access to the player's owned equipment and current loadout.
## Utilises Utils for colorful logging and JSON operations.

signal equipment_updated(owned_items: Array, equipped_item: String)

const SAVE_PATH := "user://save_data.json"

var owned_items: Array = []
var equipped_item: String = ""

## Loads save data immediately when the manager becomes active.
func _ready() -> void:
	load_data()

## Attempts to load gear data from disk, falling back to empty collections when unavailable.
func load_data() -> void:
	var default_data: Dictionary = {
		"owned_items": [],
		"equipped_item": ""
	}
	var data: Dictionary = UtilsLib.load_json(SAVE_PATH, default_data) as Dictionary
	owned_items = data.get("owned_items", [])
	equipped_item = data.get("equipped_item", "")
	UtilsLib.log("purple", "💾", "Loaded equipment data", {"owned": owned_items.size(), "equipped": equipped_item})
	emit_signal("equipment_updated", owned_items, equipped_item)

## Persists the currently tracked gear onto disk.
func save_data() -> void:
	var payload := {
		"owned_items": owned_items,
		"equipped_item": equipped_item
	}
	UtilsLib.save_json(SAVE_PATH, payload)
	emit_signal("equipment_updated", owned_items, equipped_item)

## Adds a new item to the collection, replacing duplicates of the same name.
func add_item(item: Dictionary) -> void:
	var existing_index := -1
	for i in owned_items.size():
		if owned_items[i].get("name", "") == item.get("name", ""):
			existing_index = i
			break
	if existing_index >= 0:
		owned_items[existing_index] = item
		UtilsLib.log("yellow", "🎯", "Updated existing equipment item", item)
	else:
		owned_items.append(item)
		UtilsLib.log("green", "✅", "Added new equipment item", item)
	save_data()

## Chooses an item by name to equip, ignoring invalid names.
func equip_item(item_name: String) -> void:
	if item_name == "":
		equipped_item = ""
		UtilsLib.log("yellow", "🎯", "Cleared equipped item", item_name)
		save_data()
		return
	for item in owned_items:
		if item.get("name", "") == item_name:
			equipped_item = item_name
			UtilsLib.log("green", "✅", "Equipped item", item_name)
			save_data()
			return
	UtilsLib.log("orange", "⚠️", "Attempted to equip missing item", item_name)

## Provides the dictionary data for the currently equipped gear.
func get_equipped_item() -> Dictionary:
	for item in owned_items:
		if item.get("name", "") == equipped_item:
			return item
	return {}
