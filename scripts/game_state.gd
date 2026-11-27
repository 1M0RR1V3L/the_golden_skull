extends Node
## Estado da partida (autoload "GameState").
##
## Vida, moedas, cronômetro, checkpoint, munição das flechas e pontuação final.
## O cronômetro só corre dentro das fases; como este nó é pausável,
## pausar o jogo também pausa o cronômetro.

signal hp_changed(hp: int)
signal coins_changed(coins: int)
signal arrow_changed(kind: String, ammo: int)

const LEVELS := [
	"res://scenes/cemetery.tscn",
	"res://scenes/forest.tscn",
	"res://scenes/cave.tscn",
]
const MAX_HP := 3

# --- Pontuação -------------------------------------------------------------
## Pontos por moeda.
const COIN_POINTS := 100
## Pontos por coração restante ao terminar o jogo.
const HEART_POINTS := 1500
## Bônus máximo de tempo; diminui TIME_PENALTY pontos por segundo até zerar.
const TIME_BONUS_MAX := 30000
const TIME_PENALTY := 25
const SAVE_PATH := "user://score.cfg"

# --- Flechas ---------------------------------------------------------------
## Ordem de troca com Q/E. "basic" tem munição infinita (-1).
const ARROW_KINDS := ["basic", "heavy", "poison", "quick"]

var hp := MAX_HP
var coins := 0
var elapsed := 0.0
var finished := false
## Cronômetro parado durante transições de fase.
var timer_paused := false
var ammo := {"basic": -1, "heavy": 0, "poison": 0, "quick": 0}
var arrow := "basic"

var current_level := ""
var has_checkpoint := false
var checkpoint_pos := Vector2.ZERO
## Estado no começo da fase atual (usado ao reiniciar depois do game over).
var _level_start := {}

var final_score := {}

## Contadores para os comentários do Narrador.
var deaths := 0          # game overs na partida
var level_deaths := 0    # game overs na fase atual
var level_falls := 0     # quedas em buraco na fase atual


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().scene_changed.connect(_on_scene_changed)


func _process(delta: float) -> void:
	if not finished and not timer_paused and is_in_level():
		elapsed += delta


func is_in_level() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.scene_file_path in LEVELS


## Nova partida (botão Start do menu).
func new_game() -> void:
	hp = MAX_HP
	coins = 0
	elapsed = 0.0
	finished = false
	ammo = {"basic": -1, "heavy": 0, "poison": 0, "quick": 0}
	arrow = "basic"
	current_level = ""
	has_checkpoint = false
	timer_paused = false
	final_score = {}
	deaths = 0
	level_deaths = 0
	level_falls = 0
	_emit_all()


func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	if scene == null or not (scene.scene_file_path in LEVELS):
		return
	if scene.scene_file_path != current_level:
		# Entrou numa fase nova: guarda o estado para reiniciar se morrer.
		current_level = scene.scene_file_path
		has_checkpoint = false
		_level_start = {"coins": coins, "ammo": ammo.duplicate(), "arrow": arrow, "elapsed": elapsed}
		level_deaths = 0
		level_falls = 0
	elif level_deaths >= 2:
		# Recomeçou a mesma fase depois de morrer várias vezes: o Narrador dá uma dica
		# (depois do cartão de título da transição).
		get_tree().create_timer(3.4).timeout.connect(Narrator.say.bind("dica_recomeco"))
	scene.add_child(preload("res://scripts/hud.gd").new())
	_emit_all()


## Tempo gasto na fase atual (inclui tentativas depois de game over).
func level_time() -> float:
	return elapsed - _level_start.get("elapsed", 0.0)


## Moedas ganhas na fase atual.
func level_coins() -> int:
	return coins - _level_start.get("coins", 0)


# --- Narrador ---------------------------------------------------------------
## Caiu num buraco (e sobreviveu): comenta na 2ª, 4ª e depois a cada 2 quedas.
func register_fall() -> void:
	level_falls += 1
	if level_falls == 2:
		Narrator.say("caiu_buraco_2")
	elif level_falls == 4:
		Narrator.say("caiu_buraco_4")
	elif level_falls >= 6 and level_falls % 2 == 0:
		Narrator.say("caiu_buraco_muitos")


func register_death() -> void:
	deaths += 1
	level_deaths += 1


## Chamado pela tela de game over.
func narrate_game_over() -> void:
	var cue := "game_over_muitos"
	if deaths <= 1:
		cue = "game_over_1"
	elif deaths == 2:
		cue = "game_over_2"
	elif deaths <= 4:
		cue = "game_over_3"
	Narrator.say(cue)


# --- Vida ------------------------------------------------------------------
func damage(amount := 1) -> void:
	hp = max(hp - amount, 0)
	hp_changed.emit(hp)


func heal(amount := 1) -> bool:
	if hp >= MAX_HP:
		return false
	hp = min(hp + amount, MAX_HP)
	hp_changed.emit(hp)
	return true


func set_checkpoint(pos: Vector2) -> void:
	has_checkpoint = true
	checkpoint_pos = pos


## Game over -> "Restart": recomeça a fase atual do início, com vida cheia
## e as moedas/flechas que tinha ao entrar nela. O cronômetro não volta.
func restart_level() -> void:
	hp = MAX_HP
	has_checkpoint = false
	if not _level_start.is_empty():
		coins = _level_start.coins
		ammo = _level_start.ammo.duplicate()
		arrow = _level_start.arrow
	var path := current_level if current_level != "" else LEVELS[0]
	Transition.change_scene(path)


# --- Moedas ----------------------------------------------------------------
func add_coins(amount := 1) -> void:
	coins += amount
	coins_changed.emit(coins)


## Solta "count" moedas com um pulinho a partir de "pos".
func spawn_coins(parent: Node, pos: Vector2, count: int) -> void:
	var coin_scene := preload("res://items/coins.tscn")
	for i in count:
		var c = coin_scene.instantiate()
		c.dropped = true
		c.velocity = Vector2(randf_range(-140, 140), randf_range(-380, -240))
		parent.add_child.call_deferred(c)
		c.set_deferred("global_position", pos + Vector2(randf_range(-6, 6), -10))


# --- Flechas ---------------------------------------------------------------
func add_ammo(kind: String, amount: int) -> void:
	if not ammo.has(kind) or ammo[kind] < 0:
		return
	ammo[kind] += amount
	if arrow == "basic":
		arrow = kind  # pegou flecha especial: já equipa
	arrow_changed.emit(arrow, ammo[arrow])


## Gasta uma flecha do tipo atual; volta para a básica quando acabar.
## Devolve o tipo disparado.
func use_arrow() -> String:
	var kind := arrow
	if ammo[kind] > 0:
		ammo[kind] -= 1
		if ammo[kind] == 0:
			arrow = "basic"
	arrow_changed.emit(arrow, ammo[arrow])
	return kind


## Troca de flecha (dir = 1 próxima, -1 anterior), pulando as sem munição.
func cycle_arrow(dir: int) -> void:
	var i := ARROW_KINDS.find(arrow)
	for step in ARROW_KINDS.size():
		i = wrapi(i + dir, 0, ARROW_KINDS.size())
		var k: String = ARROW_KINDS[i]
		if ammo[k] != 0:
			arrow = k
			break
	arrow_changed.emit(arrow, ammo[arrow])


# --- Fim de jogo -----------------------------------------------------------
func finish_game() -> void:
	finished = true
	var coin_pts := coins * COIN_POINTS
	var heart_pts := hp * HEART_POINTS
	var time_pts := maxi(TIME_BONUS_MAX - int(elapsed) * TIME_PENALTY, 0)
	var total := coin_pts + heart_pts + time_pts
	var best := _load_best()
	var is_record := total > best
	if is_record:
		_save_best(total)
		best = total
	final_score = {
		"coins": coins, "coin_pts": coin_pts,
		"hp": hp, "heart_pts": heart_pts,
		"time": elapsed, "time_pts": time_pts,
		"total": total, "best": best, "record": is_record,
	}


static func format_time(seconds: float) -> String:
	var m := int(seconds) / 60
	var s := int(seconds) % 60
	var cs := int(fmod(seconds, 1.0) * 10)
	return "%02d:%02d.%d" % [m, s, cs]


func _load_best() -> int:
	var cfg := ConfigFile.new()
	return cfg.get_value("score", "best", 0) if cfg.load(SAVE_PATH) == OK else 0


func _save_best(value: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", value)
	cfg.save(SAVE_PATH)


func _emit_all() -> void:
	hp_changed.emit(hp)
	coins_changed.emit(coins)
	arrow_changed.emit(arrow, ammo[arrow])
