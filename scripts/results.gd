extends Control
## Tela de resultados: pontuação final (moedas + vida + tempo) e recorde.

@onready var box := $VBoxContainer


func _ready() -> void:
	var s: Dictionary = GameState.final_score
	if s.is_empty():
		GameState.finish_game()
		s = GameState.final_score
	box.get_node("Coins").text = "MOEDAS      %d  x %d  =  %d" % [s.coins, GameState.COIN_POINTS, s.coin_pts]
	box.get_node("Hearts").text = "VIDA        %d  x %d  =  %d" % [s.hp, GameState.HEART_POINTS, s.heart_pts]
	box.get_node("Time").text = "TEMPO       %s  =  %d" % [GameState.format_time(s.time), s.time_pts]
	box.get_node("Total").text = "[center]TOTAL  %d[/center]" % s.total
	if s.record:
		box.get_node("Best").text = "[center][color=gold]NOVO RECORDE![/color][/center]"
	else:
		box.get_node("Best").text = "[center]RECORDE  %d[/center]" % s.best


func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://screens/credits.tscn")
