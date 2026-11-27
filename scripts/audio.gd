extends Node
## Áudio global (autoload "Audio").
##
## - Audio.play("jump") toca um efeito sonoro no barramento SFX.
## - Volume de Música e Efeitos (0.0 a 1.0), salvo em user://settings.cfg.
## Continua funcionando com o jogo pausado e entre trocas de cena
## (o som de morte toca enquanto vai pro game over).

const SETTINGS_PATH := "user://settings.cfg"
const SFX := {
	"jump": preload("res://sound/sfx/jump.wav"),
	"land": preload("res://sound/sfx/land.wav"),
	"coin": preload("res://sound/sfx/coin.wav"),
	"stomp": preload("res://sound/sfx/stomp.wav"),
	"hurt": preload("res://sound/sfx/hurt.wav"),
	"death": preload("res://sound/sfx/death.wav"),
	"ui_move": preload("res://sound/sfx/ui_move.wav"),
	"ui_confirm": preload("res://sound/sfx/ui_confirm.wav"),
	"pause": preload("res://sound/sfx/pause.wav"),
	"shoot": preload("res://sound/sfx/shoot.wav"),
	"checkpoint": preload("res://sound/sfx/checkpoint.wav"),
	"heal": preload("res://sound/sfx/heal.wav"),
	"chest": preload("res://sound/sfx/chest.wav"),
}
const POOL_SIZE := 8

var music_volume := 0.8
var sfx_volume := 0.8
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_players.append(p)
	_load_settings()
	_apply()


func play(sfx_name: String, pitch_variation := 0.0) -> void:
	var stream: AudioStream = SFX.get(sfx_name)
	if stream == null:
		push_warning("Efeito sonoro desconhecido: %s" % sfx_name)
		return
	var p := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = stream
	p.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	p.play()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply()
	_save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply()
	_save_settings()


func _apply() -> void:
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)


func _set_bus(bus_name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, value <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.001)))


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		music_volume = cfg.get_value("audio", "music", music_volume)
		sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save(SETTINGS_PATH)
