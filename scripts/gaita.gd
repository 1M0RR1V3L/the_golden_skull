extends Area2D
## A Gaita de Ouro: fim do jogo. Para o cronômetro, calcula a pontuação
## e vai para a tela de resultados.

var _collected := false


func _on_body_entered(body):
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	GameState.finish_game()
	Audio.play("ui_confirm")
	$sprite.play("collect")


func _on_sprite_animation_finished():
	if _collected:
		get_tree().change_scene_to_file("res://screens/results.tscn")
