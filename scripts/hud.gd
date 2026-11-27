extends CanvasLayer
## HUD da fase: corações, moedas, cronômetro e flecha equipada.
## Criado automaticamente pelo GameState ao entrar em uma fase.

const FONT := preload("res://fonts/CLASSIC_.TTF")
const HEART := preload("res://img/items_ui/Common Pick-ups/Heart_Spin (16 x 16).png")
const COIN := preload("res://img/items_ui/Common Pick-ups/Coin (16 x 16).png")
const ARROWS := {
	"basic": preload("res://img/player/Arrows/PNGs/Basic Arrow.png"),
	"heavy": preload("res://img/player/Arrows/PNGs/Heavy Arrow.png"),
	"poison": preload("res://img/player/Arrows/PNGs/Poison Arrow.png"),
	"quick": preload("res://img/player/Arrows/PNGs/Quick Arrow.png"),
}
const ARROW_NAMES := {"basic": "BASICA", "heavy": "PESADA", "poison": "VENENO", "quick": "RAPIDA"}

var _hearts: Array[TextureRect] = []
var _coin_label: Label
var _time_label: Label
var _arrow_icon: TextureRect
var _arrow_label: Label


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	GameState.hp_changed.connect(_on_hp_changed)
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.arrow_changed.connect(_on_arrow_changed)
	_on_hp_changed(GameState.hp)
	_on_coins_changed(GameState.coins)
	_on_arrow_changed(GameState.arrow, GameState.ammo[GameState.arrow])


func _process(_delta: float) -> void:
	_time_label.text = GameState.format_time(GameState.elapsed)


func _label(size: int) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font = FONT
	ls.font_size = size
	ls.outline_size = 8
	ls.outline_color = Color.BLACK
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _build() -> void:
	# Corações (canto superior esquerdo)
	var hearts := HBoxContainer.new()
	hearts.position = Vector2(20, 16)
	hearts.add_theme_constant_override("separation", 6)
	hearts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hearts)
	for i in GameState.MAX_HP:
		var h := TextureRect.new()
		h.texture = SpriteUtil.first_frame(HEART, 16)
		h.custom_minimum_size = Vector2(44, 44)
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hearts.add_child(h)
		_hearts.append(h)

	# Moedas (abaixo dos corações)
	var coins := HBoxContainer.new()
	coins.position = Vector2(20, 68)
	coins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(coins)
	var coin_icon := TextureRect.new()
	coin_icon.texture = SpriteUtil.first_frame(COIN, 16)
	coin_icon.custom_minimum_size = Vector2(36, 36)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	coins.add_child(coin_icon)
	_coin_label = _label(30)
	coins.add_child(_coin_label)

	# Cronômetro (topo, centro)
	_time_label = _label(34)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time_label.anchor_left = 0.5
	_time_label.anchor_right = 0.5
	_time_label.offset_left = -120
	_time_label.offset_right = 120
	_time_label.offset_top = 14
	add_child(_time_label)

	# Flecha equipada (canto inferior esquerdo)
	var arrow_box := HBoxContainer.new()
	arrow_box.anchor_top = 1.0
	arrow_box.anchor_bottom = 1.0
	arrow_box.offset_left = 20
	arrow_box.offset_top = -64
	arrow_box.add_theme_constant_override("separation", 10)
	arrow_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arrow_box)
	_arrow_icon = TextureRect.new()
	_arrow_icon.custom_minimum_size = Vector2(64, 32)
	_arrow_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_arrow_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	arrow_box.add_child(_arrow_icon)
	_arrow_label = _label(24)
	arrow_box.add_child(_arrow_label)


func _on_hp_changed(hp: int) -> void:
	for i in _hearts.size():
		_hearts[i].modulate = Color.WHITE if i < hp else Color(0.15, 0.15, 0.15, 0.6)


func _on_coins_changed(coins: int) -> void:
	_coin_label.text = "x %d" % coins


func _on_arrow_changed(kind: String, ammo: int) -> void:
	_arrow_icon.texture = ARROWS[kind]
	var count := "" if ammo < 0 else "  x%d" % ammo
	_arrow_label.text = "%s%s   (Q/E troca)" % [ARROW_NAMES[kind], count]
