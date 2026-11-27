extends CanvasLayer
## Transição global entre cenas (autoload "Transition").
##
## Transition.change_scene(path)    -> listras cobrem a tela, troca de cena e,
##                                     se for uma fase, mostra o cartão de título.
## Transition.level_complete(next)  -> player congela, banner "FASE CONCLUÍDA!"
##                                     com tempo/moedas da fase, música some e
##                                     então faz change_scene(next).
##
## Durante a transição o jogo não pode ser pausado e o cronômetro fica parado.

const FONT := preload("res://fonts/CLASSIC_.TTF")
const SHADER := preload("res://shader/transition.gdshader")
const GOLD := Color(1.0, 0.843, 0.0)
const LEVEL_TITLES := {
	"res://scenes/cemetery.tscn": ["FASE 1", "O CEMITERIO"],
	"res://scenes/forest.tscn": ["FASE 2", "A FLORESTA"],
	"res://scenes/cave.tscn": ["FASE 3", "A PEDRA DA CAVEIRA"],
}
const WIPE_TIME := 0.6
const CARD_TIME := 1.6
const BANNER_TIME := 2.2

var busy := false

var _wipe: ColorRect
var _mat: ShaderMaterial
var _card: Control
var _card_top: Label
var _card_title: Label
var _banner: Control
var _banner_title: Label
var _banner_stats: Label


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter("lines", 12.0)
	_mat.set_shader_parameter("line_color_a", Color.BLACK)
	_mat.set_shader_parameter("line_color_b", Color.BLACK)
	_mat.set_shader_parameter("threshold", 0.0)
	_wipe = ColorRect.new()
	_wipe.material = _mat
	_wipe.set_anchors_preset(Control.PRESET_FULL_RECT)
	_wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_wipe)

	# Cartão de título da fase (aparece com a tela coberta).
	_card = Control.new()
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.visible = false
	add_child(_card)
	var card_box := VBoxContainer.new()
	card_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_box.alignment = BoxContainer.ALIGNMENT_CENTER
	card_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(card_box)
	_card_top = _label(36, Color.WHITE)
	_card_title = _label(72, GOLD)
	card_box.add_child(_card_top)
	card_box.add_child(_card_title)

	# Banner de fase concluída (por cima do jogo).
	_banner = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7)
	style.border_color = GOLD
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	_banner.add_theme_stylebox_override("panel", style)
	_banner.anchor_left = 0.0
	_banner.anchor_right = 1.0
	_banner.anchor_top = 0.5
	_banner.anchor_bottom = 0.5
	_banner.offset_top = -90
	_banner.offset_bottom = 90
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.visible = false
	add_child(_banner)
	var banner_box := VBoxContainer.new()
	banner_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_banner.add_child(banner_box)
	_banner_title = _label(60, GOLD)
	_banner_stats = _label(30, Color.WHITE)
	banner_box.add_child(_banner_title)
	banner_box.add_child(_banner_stats)


func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font = FONT
	ls.font_size = size
	ls.font_color = color
	ls.outline_size = 10
	ls.outline_color = Color.BLACK
	l.label_settings = ls
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func change_scene(path: String) -> void:
	if busy:
		return
	busy = true
	GameState.timer_paused = true
	await _tween_wipe(1.0)
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().scene_changed
	if LEVEL_TITLES.has(path):
		# Segura a fase parada enquanto o cartão de título aparece.
		get_tree().paused = true
		_card_top.text = LEVEL_TITLES[path][0]
		_card_title.text = LEVEL_TITLES[path][1]
		_card.modulate.a = 0.0
		_card.visible = true
		var t := create_tween()
		t.tween_property(_card, "modulate:a", 1.0, 0.25)
		t.tween_interval(CARD_TIME)
		t.tween_property(_card, "modulate:a", 0.0, 0.25)
		await t.finished
		_card.visible = false
		get_tree().paused = false
	GameState.timer_paused = false
	await _tween_wipe(0.0)
	busy = false


func level_complete(next_path: String) -> void:
	if busy:
		return
	busy = true
	GameState.timer_paused = true
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("freeze"):
		player.freeze()
	Audio.play("checkpoint")
	_fade_music()
	_banner_title.text = "FASE CONCLUIDA!"
	_banner_stats.text = "TEMPO %s     MOEDAS +%d" % [
		GameState.format_time(GameState.level_time()), GameState.level_coins()]
	_banner.modulate.a = 0.0
	_banner.scale = Vector2(1, 0.2)
	_banner.pivot_offset = Vector2(0, 90)
	_banner.visible = true
	var t := create_tween().set_parallel()
	t.tween_property(_banner, "modulate:a", 1.0, 0.2)
	t.tween_property(_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(BANNER_TIME).timeout
	busy = false
	await change_scene(next_path)
	_banner.visible = false


func _tween_wipe(to: float) -> void:
	var t := create_tween()
	t.tween_method(func(v): _mat.set_shader_parameter("threshold", v),
		_mat.get_shader_parameter("threshold"), to, WIPE_TIME)
	await t.finished
	if to >= 1.0:
		_banner.visible = false


func _fade_music() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	for p in scene.find_children("*", "AudioStreamPlayer", true, false):
		if p.bus == &"Music" and p.playing:
			create_tween().tween_property(p, "volume_db", -40.0, BANNER_TIME)
