extends Node
class_name Inventory

# Max inventory size per player
const MAX_INVENTORY_SIZE = 8

# Items stored as array of ItemType
var items: Array[ItemData.ItemType] = []

signal item_added(item_type: ItemData.ItemType)
signal item_removed(item_type: ItemData.ItemType)
signal inventory_full


# Add item to inventory
func add_item(item_type: ItemData.ItemType) -> bool:
	if items.size() >= MAX_INVENTORY_SIZE:
		inventory_full.emit()
		return false
	
	items.append(item_type)
	item_added.emit(item_type)
	print("Added item: ", ItemData.get_item_info(item_type)["name"])
	return true


# Remove item from inventory
func remove_item(item_type: ItemData.ItemType) -> bool:
	var index = items.find(item_type)
	if index != -1:
		items.remove_at(index)
		item_removed.emit(item_type)
		return true
	return false


# Check if has item
func has_item(item_type: ItemData.ItemType) -> bool:
	return item_type in items


# Get all items
func get_items() -> Array[ItemData.ItemType]:
	return items


# Get item count
func get_item_count() -> int:
	return items.size()


# Is inventory full
func is_full() -> bool:
	return items.size() >= MAX_INVENTORY_SIZE


# Clear inventory
func clear() -> void:
	items.clear()
