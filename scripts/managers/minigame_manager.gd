extends Node

# Minigame outcomes
enum Outcome {
	WIN,
	LOSE,
	DRAW
}

# Minigame rewards
var minigame_rewards = [
	GameManager.ItemType.SHIELD,
	GameManager.ItemType.DOUBLE_DICE,
	GameManager.ItemType.TELEPORT,
	GameManager.ItemType.REVERSE_CARD,
	GameManager.ItemType.SKIP_IMMUNITY
]


# Simple random minigame (can be replaced with actual minigames later)
func play_minigame(player: Player) -> Outcome:
	print("🎮 Starting minigame for ", player.player_name)
	
	# For now: 50% chance to win
	var result = randi() % 2
	
	if result == 0:
		return Outcome.WIN
	else:
		return Outcome.LOSE


func give_reward(player: Player) -> void:
	var random_item = minigame_rewards[randi() % minigame_rewards.size()]
	player.add_item(random_item)
	
	var item_info = GameManager.get_item_data(random_item)
	print("🎁 ", player.player_name, " won: ", item_info["name"])
