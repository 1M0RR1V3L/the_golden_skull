extends CanvasLayer
## Narrador (autoload "Narrator"): comentários curtos que aparecem embaixo da tela
## sem pausar o jogo. As falas ficam em scripts/dialogue/narrador.dialogue
## (editáveis no editor do Dialogue Manager) e uma é sorteada a cada vez.
##
## Narrator.say("caiu_buraco_2")

const DIALOGUE := preload("res://scripts/dialogue/narrador.dialogue")
const FONT := preload("res://fonts/CLASSIC_.TTF")
const GOLD := Color(1.0, 0.843, 0.0)
const CHARS_PER_SECOND := 45.0
const MIN_HOLD := 2.5

var _panel: PanelContainer
var _name: Label
var _text: RichTextLabel
var _tween: Tween
var _request := 0


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.03, 0.02, 0.85)
	style.border_color = GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", style)
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -440
	_panel.offset_right = 440
	_panel.offset_top = -190
	_panel.offset_bottom = -90
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	add_child(_panel)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(box)
	_name = Label.new()
	var ls := LabelSettings.new()
	ls.font = FONT
	ls.font_size = 22
	ls.font_color = GOLD
	_name.label_settings = ls
	box.add_child(_name)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_font_override("normal_font", FONT)
	_text.add_theme_font_size_override("normal_font_size", 22)
	box.add_child(_text)


## Mostra uma fala sorteada da situação "cue". Uma fala nova substitui a atual.
func say(cue: String) -> void:
	_request += 1
	var my_request := _request
	var line = await DialogueManager.get_next_dialogue_line(DIALOGUE, cue)
	if line == null or my_request != _request:
		return
	_name.text = (line.character if line.character != "" else "Narrador").to_upper()
	_text.text = line.text
	_text.visible_ratio = 0.0
	if _tween:
		_tween.kill()
	_panel.visible = true
	_panel.modulate.a = 0.0
	var chars := _text.get_total_character_count()
	var typing := chars / CHARS_PER_SECOND
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.15)
	_tween.tween_property(_text, "visible_ratio", 1.0, typing)
	_tween.tween_interval(maxf(MIN_HOLD, chars / 18.0))
	_tween.tween_property(_panel, "modulate:a", 0.0, 0.35)
	_tween.tween_callback(func(): _panel.visible = false)


func is_showing() -> bool:
	return _panel.visible
