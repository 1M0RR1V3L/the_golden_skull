extends Node2D

const FIRST_LEVEL := "res://scenes/cemetery.tscn"
const DIALOGUE := preload("res://scripts/dialogue/introduction.dialogue")


func _ready() -> void:
	DialogueManager.show_example_dialogue_balloon(DIALOGUE)


func _input(event: InputEvent) -> void:
	# Esc pula o diálogo. Usa _input porque o balão de diálogo
	# consome todas as teclas em _unhandled_input enquanto está aberto.
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_start_game()


func _unhandled_input(event: InputEvent) -> void:
	# Enter inicia o jogo depois que o diálogo termina
	# (durante o diálogo, o Enter só avança as falas).
	if event.is_action_pressed("Enter"):
		_start_game()


func _start_game() -> void:
	get_tree().change_scene_to_file(FIRST_LEVEL)


func _on_start_button_pressed() -> void:
	_start_game()


func _on_skip_button_pressed() -> void:
	_start_game()
