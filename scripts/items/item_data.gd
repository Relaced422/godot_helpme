extends Node
class_name ItemData

# Item rarity tiers
enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

# Item types
enum ItemType {
	# Common
	SYSTEM_JAMMER,
	QUANTUM_SLIPSTREAM,
	SOLAR_FLARE_SHOCK,
	MINOR_WORMHOLE,
	
	# Rare
	ASTEROID_KNOCKBACK,
	CRYO_LOCK,
	DARK_MATTER_TRAP,
	ALIEN_DISPLACEMENT_RAY,
	
	# Epic
	MICRO_BLACK_HOLE,
	TIME_REWIND_CHIP,
	CORRUPTION_PULSE,
	
	# Legendary
	WORMHOLE_COLLAPSE,
	SUPERNOVA_PULSE,
	EVENT_HORIZON_ENGINE,
	COSMIC_GLITCH_CORE
}

# Item definitions
static var items = {
	# COMMON (55% total)
	ItemType.SYSTEM_JAMMER: {
		"name": "🛰 System Jammer",
		"description": "Target's next roll is forced to 1",
		"rarity": Rarity.COMMON,
		"requires_target": true,
		"effect": "force_roll_1"
	},
	ItemType.QUANTUM_SLIPSTREAM: {
		"name": "🌀 Quantum Slipstream",
		"description": "Target moves back 3 tiles",
		"rarity": Rarity.COMMON,
		"requires_target": true,
		"effect": "move_back_3"
	},
	ItemType.SOLAR_FLARE_SHOCK: {
		"name": "🌋 Solar Flare Shock",
		"description": "Target rolls twice next turn and takes the lower result",
		"rarity": Rarity.COMMON,
		"requires_target": true,
		"effect": "roll_twice_lower"
	},
	ItemType.MINOR_WORMHOLE: {
		"name": "🌠 Minor Wormhole",
		"description": "Teleport target to a random tile behind them (max 4 tiles back)",
		"rarity": Rarity.COMMON,
		"requires_target": true,
		"effect": "random_back_4"
	},
	
	# RARE (30% total)
	ItemType.ASTEROID_KNOCKBACK: {
		"name": "☄️ Asteroid Knockback",
		"description": "Move target back to nearest danger tile (or 5 tiles back)",
		"rarity": Rarity.RARE,
		"requires_target": true,
		"effect": "knockback_danger"
	},
	ItemType.CRYO_LOCK: {
		"name": "🧊 Cryo Lock",
		"description": "Target skips their next turn",
		"rarity": Rarity.RARE,
		"requires_target": true,
		"effect": "skip_turn"
	},
	ItemType.DARK_MATTER_TRAP: {
		"name": "🪤 Dark Matter Trap",
		"description": "Place on a tile. Next player landing there moves back 5",
		"rarity": Rarity.RARE,
		"requires_target": false,
		"effect": "place_trap"
	},
	ItemType.ALIEN_DISPLACEMENT_RAY: {
		"name": "🛸 Alien Displacement Ray",
		"description": "Swap positions with target player",
		"rarity": Rarity.RARE,
		"requires_target": true,
		"effect": "swap_positions"
	},
	
	# EPIC (12% total)
	ItemType.MICRO_BLACK_HOLE: {
		"name": "🌑 Micro Black Hole",
		"description": "Target's next 2 rolls are halved (rounded down)",
		"rarity": Rarity.EPIC,
		"requires_target": true,
		"effect": "halve_rolls_2"
	},
	ItemType.TIME_REWIND_CHIP: {
		"name": "🧬 Time Rewind Chip",
		"description": "Target returns to the tile they were on at the start of their last turn",
		"rarity": Rarity.EPIC,
		"requires_target": true,
		"effect": "rewind_last_turn"
	},
	ItemType.CORRUPTION_PULSE: {
		"name": "🌌 Corruption Pulse",
		"description": "Turn the next 3 tiles ahead of target into danger tiles",
		"rarity": Rarity.EPIC,
		"requires_target": true,
		"effect": "corrupt_tiles_3"
	},
	
	# LEGENDARY (3% total)
	ItemType.WORMHOLE_COLLAPSE: {
		"name": "🌠 Wormhole Collapse",
		"description": "Teleport target to any random tile on the board",
		"rarity": Rarity.LEGENDARY,
		"requires_target": true,
		"effect": "random_teleport"
	},
	ItemType.SUPERNOVA_PULSE: {
		"name": "🌋 Supernova Pulse",
		"description": "All other players move back 3 tiles",
		"rarity": Rarity.LEGENDARY,
		"requires_target": false,
		"effect": "all_move_back_3"
	},
	ItemType.EVENT_HORIZON_ENGINE: {
		"name": "🌑 Event Horizon Engine",
		"description": "Send target back to the start tile",
		"rarity": Rarity.LEGENDARY,
		"requires_target": true,
		"effect": "send_to_start"
	},
	ItemType.COSMIC_GLITCH_CORE: {
		"name": "🧨 Cosmic Glitch Core",
		"description": "Shuffle all player positions randomly",
		"rarity": Rarity.LEGENDARY,
		"requires_target": false,
		"effect": "shuffle_positions"
	}
}

# Drop rate weights
static var drop_weights = {
	Rarity.COMMON: 55,
	Rarity.RARE: 30,
	Rarity.EPIC: 12,
	Rarity.LEGENDARY: 3
}


# Get random item based on rarity weights
static func get_random_item() -> ItemType:
	# Calculate total weight
	var total_weight = 0
	for weight in drop_weights.values():
		total_weight += weight
	
	# Random pick
	var rand = randi() % total_weight
	var current_weight = 0
	var selected_rarity = Rarity.COMMON
	
	for rarity in drop_weights:
		current_weight += drop_weights[rarity]
		if rand < current_weight:
			selected_rarity = rarity
			break
	
	# Get all items of selected rarity
	var items_of_rarity = []
	for item_type in items:
		if items[item_type]["rarity"] == selected_rarity:
			items_of_rarity.append(item_type)
	
	# Return random item from that rarity
	if items_of_rarity.is_empty():
		return ItemType.SYSTEM_JAMMER  # Fallback
	
	return items_of_rarity[randi() % items_of_rarity.size()]


# Get item info
static func get_item_info(item_type: ItemType) -> Dictionary:
	return items.get(item_type, {})
