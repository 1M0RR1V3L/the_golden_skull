extends Control	

func _ready():
		# No navegador não existe "fechar o jogo": esconde o Quit.
		if OS.has_feature("web"):
			$VBoxContainer/QuitButton.visible = false
			$VBoxContainer/OptionsButton.focus_neighbor_bottom = ^"../StartButton"
			$VBoxContainer/StartButton.focus_neighbor_top = ^"../OptionsButton"
		$VBoxContainer/StartButton.grab_focus()
		
func _on_start_button_pressed():
	GameState.new_game()
	get_tree().change_scene_to_file("res://scenes/introduction.tscn")

func _on_credits_button_pressed():
	get_tree().change_scene_to_file("res://screens/credits.tscn")

func _on_controls_button_pressed():
	get_tree().change_scene_to_file("res://screens/controles.tscn")
	
func _on_options_button_pressed():
	get_tree().change_scene_to_file("res://screens/options.tscn")

func _on_quit_button_pressed():
	get_tree().quit()

