extends Control

# Called when the node enters the scene tree for the first time.

@onready var n_username := %Username
@onready var n_key := %Key

var rcheevos : RetroAchievementsIntegration

func _ready():
	RetroHubConfig.config._should_save = false
	RetroHubConfig.config.integration_rcheevos_enabled = true
	n_username.text = RetroHubConfig._get_credential("rcheevos_username")
	n_key.text = RetroHubConfig._get_credential("rcheevos_api_key")
	
	rcheevos = RetroAchievementsIntegration.new()
	add_child(rcheevos)
	await get_tree().process_frame
	if not rcheevos:
		get_tree().quit()

	var funcs := [
		["get_achievement_of_the_week", rcheevos.Raw.get_achievement_of_the_week, []],
		["get_claims", rcheevos.Raw.get_claims, ["dropped"]],
		["get_active_claims", rcheevos.Raw.get_active_claims, []],
		["get_top_ten_users", rcheevos.Raw.get_top_ten_users, []],
		["get_user_recent_achievements", rcheevos.Raw.get_user_recent_achievements, ["xelnia", 60]],
		["get_achievements_earned_between", rcheevos.Raw.get_achievements_earned_between, ["Ev1lbl0w", 1695772800, 1696204800]],
		["get_achievements_earned_on_day", rcheevos.Raw.get_achievements_earned_on_day, ["Ev1lbl0w", "2023-09-27"]],
		["get_game_info_and_user_progress", rcheevos.Raw.get_game_info_and_user_progress, ["Ev1lbl0w", 264]],
		["get_user_awards", rcheevos.Raw.get_user_awards, ["xelnia"]],
		["get_user_claims", rcheevos.Raw.get_user_claims, ["Jamiras"]],
		["get_user_completed_games", rcheevos.Raw.get_user_completed_games, ["xelnia"]],
		["get_user_game_rank_and_score", rcheevos.Raw.get_user_game_rank_and_score, ["xelnia", 14402]],
		["get_user_points", rcheevos.Raw.get_user_points, ["xelnia"]],
		["get_user_progress", rcheevos.Raw.get_user_progress, ["xelnia", [1, 14402]]],
		["get_user_recently_played_games", rcheevos.Raw.get_user_recently_played_games, ["xelnia", 10, 0]],
		["get_user_summary", rcheevos.Raw.get_user_summary, ["xelnia", 0, 5]],
		["get_achievement_count", rcheevos.Raw.get_achievement_count, [14402]],
		["get_achievement_distribution", rcheevos.Raw.get_achievement_distribution, [14402]],
		["get_game", rcheevos.Raw.get_game, [14402]],
		["get_game_extended", rcheevos.Raw.get_game_extended, [10433]],
		["get_game_rank_and_score", rcheevos.Raw.get_game_rank_and_score, [14402, "latest-masters"]],
		["get_console_ids", rcheevos.Raw.get_console_ids, []],
		["get_game_list", rcheevos.Raw.get_game_list, [1, true, true]],
		["get_achievement_unlocks", rcheevos.Raw.get_achievement_unlocks, [13876, 50, 0]],
	]

	for f in funcs:
		var button := Button.new()
		button.text = f[0]
		button.pressed.connect(func():
			var args := [rcheevos.build_auth()]
			args.append_array(f[2])
			%Label.text = "<waiting>"
			var response : RetroAchievementsIntegration.Raw.Response = await f[1].callv(args)
			%Label.text = "<writing>"
			await get_tree().process_frame
			if response:
				if not response.godot_error:
					%Label.text = "HTTP: %d\n\n%s" % [response.response_code, JSON.stringify(response.body, "  ", false)]
				else:
					%Label.text = "Internal error: %d" % response.godot_error
			else:
				%Label.text = "<null>"
		)
		%Buttons.add_child(button)

	for data: RetroHubGameData in RetroHubConfig.games:
		var button := Button.new()
		button.text = "[%s] %s" % [data.system.name, data.name]
		button.clip_text = true
		button.pressed.connect(func():
			%Label.text = "<waiting>"
			var info := await rcheevos.get_game_info(data)
			var text : String = "Status: %s" % RetroAchievementsIntegration.GameInfo.Error.keys()[info.err]
			if info.err:
				%Label.text = text
				return

			%Label.text = "<writing>"
			await get_tree().process_frame
			text += "\n\n[%d] %s\n\n" % [info.id, data.name]
			for achievement in info.achievements:
				achievement.load_icon()
				var type_char := ""
				match achievement.type:
					RetroAchievementsIntegration.Achievement.Type.MISSABLE:
						type_char = "?"
					RetroAchievementsIntegration.Achievement.Type.PROGRESSION:
						type_char = "."
					RetroAchievementsIntegration.Achievement.Type.WIN:
						type_char = "!"
					_:
						type_char = " "
				text += "[%s] [%s] %s - %s\n" % [
					"*" if achievement.unlocked else " ",
					type_char,
					achievement.title,
					achievement.description
				]
			%Label.text = text
		)
		%DataButtons.add_child(button)

func _on_username_text_changed(new_text):
	rcheevos._api_username = new_text


func _on_key_text_changed(new_text):
	rcheevos._api_key = new_text
