extends CanvasLayer

const MENU_SCENE := "res://screens/menu.tscn"

@onready var pause_button: Button = $pause_button
@onready var overlay: ColorRect = $ColorRect
@onready var menu_screen: VBoxContainer = $menu_screen
@onready var resume_button: Button = $menu_screen/Resume_button


func _ready() -> void:
	_set_paused(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	overlay.visible = paused
	menu_screen.visible = paused
	pause_button.visible = not paused
	if paused:
		resume_button.grab_focus()


func _on_pause_button_pressed() -> void:
	_set_paused(true)


func _on_resume_button_pressed() -> void:
	_set_paused(false)


func _on_back_menu_button_pressed() -> void:
	# Precisa despausar antes de trocar de cena, senão o menu abre congelado.
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
