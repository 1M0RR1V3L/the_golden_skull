extends Control

@onready var music_slider: HSlider = $VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $VBoxContainer/SfxSlider
@onready var music_label: RichTextLabel = $VBoxContainer/MusicLabel
@onready var sfx_label: RichTextLabel = $VBoxContainer/SfxLabel


func _ready() -> void:
	music_slider.value = Audio.music_volume
	sfx_slider.value = Audio.sfx_volume
	_update_labels()
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	UiFocus.quiet()
	music_slider.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()


func _on_music_changed(value: float) -> void:
	Audio.set_music_volume(value)
	_update_labels()


func _on_sfx_changed(value: float) -> void:
	Audio.set_sfx_volume(value)
	Audio.play("coin")  # amostra do volume dos efeitos
	_update_labels()


func _update_labels() -> void:
	music_label.text = "MUSICA  %d%%" % roundi(music_slider.value * 100)
	sfx_label.text = "EFEITOS  %d%%" % roundi(sfx_slider.value * 100)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://screens/menu.tscn")
