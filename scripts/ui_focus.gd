extends Node
## Destaque padrão para botões e sliders de menu (autoload).
##
## - O item selecionado (foco) fica dourado, com fundo/sublinhado; botões crescem um pouco.
## - Passar o mouse sobre um item também o seleciona, para mouse e teclado
##   nunca mostrarem dois itens "selecionados" ao mesmo tempo.
## - Telas em res://screens/ que abrirem sem nada selecionado ganham foco
##   no primeiro botão, para as setas funcionarem de imediato.
## - Sons: "ui_move" ao trocar de seleção, "ui_confirm" ao apertar um botão.
##
## Itens com focus_mode = FOCUS_NONE (ex.: botão II de pausa, SKIP) são ignorados.

const HIGHLIGHT := Color(1.0, 0.843, 0.0)        # dourado, mesma cor do título do menu
const SELECTED_SCALE := Vector2(1.08, 1.08)

var _focus_style: StyleBoxFlat
## Evita tocar "ui_move" quando o foco é dado por código ao abrir uma tela.
var _quiet_until_frame := 0


func _ready() -> void:
	_focus_style = StyleBoxFlat.new()
	_focus_style.bg_color = Color(1.0, 0.843, 0.0, 0.12)
	_focus_style.border_color = HIGHLIGHT
	_focus_style.border_width_bottom = 3
	_focus_style.set_corner_radius_all(4)
	_focus_style.content_margin_left = 12
	_focus_style.content_margin_right = 12
	_add_font_fallback()
	get_tree().node_added.connect(_on_node_added)
	get_tree().scene_changed.connect(_on_scene_changed)
	# A primeira cena (menu) entra na árvore antes deste autoload ficar pronto,
	# então os botões dela não passam pelo node_added: configura agora.
	_setup_existing.call_deferred()


## A fonte CLASSIC_.TTF só tem letras (sem números e pontuação). No PC a Godot
## completa com fontes do Windows, mas na Web não existem fontes do sistema e
## números como os do cronômetro aparecem quebrados. A fonte embutida da Godot
## vira a reserva, igual em todas as plataformas.
func _add_font_fallback() -> void:
	var font: FontFile = load("res://fonts/CLASSIC_.TTF")
	if font and ThemeDB.fallback_font and not font.fallbacks.has(ThemeDB.fallback_font):
		var list := font.fallbacks
		list.append(ThemeDB.fallback_font)
		font.fallbacks = list


func _setup_existing() -> void:
	for node in get_tree().root.find_children("*", "Control", true, false):
		_on_node_added(node)
	var focused := get_viewport().gui_get_focus_owner()
	if focused is Button and focused.has_meta("ui_focus"):
		_quiet_until_frame = Engine.get_process_frames() + 2
		_set_selected(focused, true)


func _on_node_added(node: Node) -> void:
	if not (node is Control) or node.focus_mode == Control.FOCUS_NONE:
		return
	if node.has_meta("ui_focus"):
		return  # já configurado
	node.set_meta("ui_focus", true)
	if node is Button:
		_setup_button(node)
	elif node is Slider:
		_setup_slider(node)


func _setup_button(button: Button) -> void:
	button.add_theme_stylebox_override("focus", _focus_style)
	button.add_theme_color_override("font_focus_color", HIGHLIGHT)
	button.add_theme_color_override("font_hover_color", HIGHLIGHT)
	button.add_theme_color_override("font_hover_pressed_color", HIGHLIGHT)
	button.mouse_entered.connect(_on_mouse_entered.bind(button))
	button.focus_entered.connect(_set_selected.bind(button, true))
	button.focus_exited.connect(_set_selected.bind(button, false))
	button.pressed.connect(func(): Audio.play("ui_confirm"))
	button.resized.connect(func(): button.pivot_offset = button.size / 2.0)


func _setup_slider(slider: Slider) -> void:
	slider.add_theme_stylebox_override("focus", _focus_style)
	slider.mouse_entered.connect(_on_mouse_entered.bind(slider))
	slider.focus_entered.connect(_play_move)


func _on_mouse_entered(control: Control) -> void:
	if control.is_visible_in_tree() and not (control is BaseButton and control.disabled):
		control.grab_focus()


func _set_selected(button: Button, selected: bool) -> void:
	button.pivot_offset = button.size / 2.0
	var tween := button.create_tween()
	tween.tween_property(button, "scale", SELECTED_SCALE if selected else Vector2.ONE, 0.08)
	if selected:
		_play_move()


## Chame antes de dar foco por código para não tocar o som de navegação.
func quiet() -> void:
	_quiet_until_frame = Engine.get_process_frames() + 2


func _play_move() -> void:
	if Engine.get_process_frames() > _quiet_until_frame:
		Audio.play("ui_move")


func _on_scene_changed() -> void:
	# Foco dado por código nos primeiros frames da tela não faz som.
	_quiet_until_frame = Engine.get_process_frames() + 3
	var scene := get_tree().current_scene
	if scene == null or not scene.scene_file_path.begins_with("res://screens/"):
		return
	await get_tree().process_frame
	if get_viewport().gui_get_focus_owner() != null:
		return
	for b in scene.find_children("*", "Button", true, false):
		if b.is_visible_in_tree() and b.focus_mode != Control.FOCUS_NONE and not b.disabled:
			b.grab_focus()
			return
