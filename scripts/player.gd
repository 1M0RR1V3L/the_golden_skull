extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

## Tempo (s) após sair de uma beirada em que ainda dá para pular.
const COYOTE_TIME := 0.1
## Tempo (s) que um pulo apertado antes de tocar o chão fica "guardado".
const JUMP_BUFFER_TIME := 0.12
## Ao soltar o pulo durante a subida, a velocidade é multiplicada por isto (pulo curto).
const JUMP_CUT := 0.45

## Degraus até esta altura (px) são subidos andando, sem pular.
## As "ladeiras" das fases são feitas de degraus de tile de 8 a 32 px.
const MAX_STEP_UP := 34.0
## Gruda no chão ao descer ladeiras/degraus (em vez de "voar" de degrau em degrau).
const FLOOR_SNAP := 18.0

## Invencibilidade (s) depois de levar dano ou voltar do buraco.
const INVINCIBLE_TIME := 1.2
## Empurrão ao levar dano.
const KNOCKBACK := Vector2(280, -260)
const KNOCKBACK_TIME := 0.25

## Intervalo mínimo entre disparos por tipo de flecha (s).
const SHOOT_COOLDOWN := {"basic": 0.45, "heavy": 0.65, "poison": 0.5, "quick": 0.18}
## Quadro da animação "attack" em que a flecha sai.
const SHOOT_FRAME := 4

## Quanto a câmera se adianta (em pixels do mundo) na direção em que o player olha.
const CAMERA_LOOK_AHEAD := 140.0
## Velocidade com que a câmera desliza para o lado ao virar (maior = mais rápido).
const CAMERA_LOOK_AHEAD_SPEED := 2.5

const DUST_TEXTURE := preload("res://img/items_ui/Effects/Dust (16 x 16).png")

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animation := $animation as AnimatedSprite2D
@onready var camera := $camera as Camera2D
@onready var collision := $collision as CollisionShape2D
var is_jumping := false
var facing := 1.0
var spawn_point := Vector2.ZERO

var _coyote := 0.0
var _jump_buffer := 0.0
var _was_on_floor := true
var _invincible := 0.0
var _knockback := 0.0
var _stomp_grace := 0.0
var _shoot_cooldown := 0.0
var _attacking := false
var _pending_arrow := ""
var _dead := false
var _frozen := false
var _dust_frames: SpriteFrames


func _ready() -> void:
	add_to_group("player")
	spawn_point = global_position
	floor_snap_length = FLOOR_SNAP
	floor_constant_speed = true
	_fit_camera_to_level()
	_dust_frames = SpriteUtil.frames_from_sheets({"default": [DUST_TEXTURE, 16, 18.0, false]})
	# Animação de ataque: uma vez só e rápida (no .tscn ela estava em loop a 5 fps).
	animation.sprite_frames.set_animation_loop("attack", false)
	animation.sprite_frames.set_animation_speed("attack", 22.0)
	animation.frame_changed.connect(_on_animation_frame_changed)
	animation.animation_finished.connect(_on_animation_finished)


func _physics_process(delta):
	if _dead:
		return
	if _frozen:
		# Fase concluída: só cai até o chão e fica parado.
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = 0.0
		animation.play("idle")
		move_and_slide()
		return
	var on_floor := is_on_floor()
	_tick_timers(delta)

	# Add the gravity.
	if not on_floor:
		velocity.y += gravity * delta

	# Coyote time e jump buffer.
	_coyote = COYOTE_TIME if on_floor else maxf(_coyote - delta, 0.0)
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER_TIME
	else:
		_jump_buffer = maxf(_jump_buffer - delta, 0.0)

	# Handle Jump.
	if _jump_buffer > 0.0 and _coyote > 0.0 and _knockback <= 0.0:
		velocity.y = JUMP_VELOCITY
		is_jumping = true
		_jump_buffer = 0.0
		_coyote = 0.0
		Audio.play("jump", 0.05)
		_spawn_dust()
	elif on_floor and velocity.y >= 0.0:
		is_jumping = false

	# Pulo de altura variável: soltar o botão na subida corta o pulo.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT

	# Arco.
	if Input.is_action_just_pressed("arrow_next"):
		GameState.cycle_arrow(1)
	elif Input.is_action_just_pressed("arrow_prev"):
		GameState.cycle_arrow(-1)
	if Input.is_action_pressed("attack") and _shoot_cooldown <= 0.0 and not _attacking:
		_start_shot()

	# Movimento.
	var direction = Input.get_axis("left", "right")
	if _knockback > 0.0:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 2)
	elif direction != 0:
		velocity.x = direction * SPEED
		if not _attacking:
			facing = sign(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	animation.scale.x = facing * 3
	_update_animation(direction)

	_try_step_up(delta)
	move_and_slide()

	# Aterrissagem.
	if is_on_floor() and not _was_on_floor:
		Audio.play("land", 0.1)
		_spawn_dust()
	_was_on_floor = is_on_floor()

	_update_camera(delta)


# Se há um degrau baixo logo à frente, ergue o player o suficiente para passar.
func _try_step_up(delta: float) -> void:
	if not is_on_floor() or velocity.y < 0.0 or absf(velocity.x) < 1.0:
		return
	var motion := Vector2(velocity.x * delta, 0.0)
	# Só o cenário conta como degrau (não dá para "subir" em cima de inimigos).
	var mask := collision_mask
	collision_mask = 2
	var raise := 0.0
	if test_move(global_transform, motion):
		var h := 2.0
		while h <= MAX_STEP_UP:
			var up := Vector2(0.0, -h)
			if test_move(global_transform, up):
				break  # teto/obstáculo acima
			if not test_move(global_transform.translated(up), motion):
				raise = h
				break
			h += 2.0
	collision_mask = mask
	global_position.y -= raise


func _tick_timers(delta: float) -> void:
	_shoot_cooldown = maxf(_shoot_cooldown - delta, 0.0)
	_knockback = maxf(_knockback - delta, 0.0)
	_stomp_grace = maxf(_stomp_grace - delta, 0.0)
	if _invincible > 0.0:
		_invincible -= delta
		animation.visible = _invincible <= 0.0 or int(_invincible * 12) % 2 == 0


func _update_animation(direction: float) -> void:
	if _attacking:
		return
	if is_jumping or not is_on_floor():
		animation.play("jump")
	elif direction != 0:
		animation.play("run")
	else:
		animation.play("idle")


# --- Arco ------------------------------------------------------------------
func _start_shot() -> void:
	_attacking = true
	_pending_arrow = GameState.arrow
	_shoot_cooldown = SHOOT_COOLDOWN[_pending_arrow]
	animation.speed_scale = 2.0 if _pending_arrow == "quick" else 1.0
	animation.play("attack")


func _on_animation_frame_changed() -> void:
	if _attacking and animation.animation == "attack" and animation.frame == SHOOT_FRAME and _pending_arrow != "":
		_fire()


func _on_animation_finished() -> void:
	if animation.animation == "attack":
		if _pending_arrow != "":
			_fire()  # garantia, caso o quadro tenha sido pulado
		_attacking = false
		animation.speed_scale = 1.0


func _fire() -> void:
	_pending_arrow = ""
	var kind := GameState.use_arrow()
	var arrow: Area2D = preload("res://scripts/arrow.gd").create(kind, facing)
	get_parent().add_child(arrow)
	arrow.global_position = global_position + Vector2(facing * 34, -8)
	Audio.play("shoot", 0.1)


# --- Dano / vida -----------------------------------------------------------
func take_damage(amount: int, from: Vector2) -> void:
	if _frozen or _dead or _invincible > 0.0 or _stomp_grace > 0.0:
		return
	GameState.damage(amount)
	Audio.play("hurt")
	var away := signf(global_position.x - from.x)
	if away == 0.0:
		away = -facing
	velocity = Vector2(away * KNOCKBACK.x, KNOCKBACK.y)
	_knockback = KNOCKBACK_TIME
	_invincible = INVINCIBLE_TIME
	if GameState.hp <= 0:
		die()


## Altura dos pés (base da colisão), usada para decidir se foi pisão.
func feet_y() -> float:
	return collision.global_position.y + (collision.shape as RectangleShape2D).size.y / 2.0


## Fase concluída: para o player (não se move nem leva dano).
func freeze() -> void:
	_frozen = true
	_attacking = false
	_invincible = 0.0
	animation.visible = true


## Quique ao pisar num inimigo (chamado pelo hitbox do inimigo).
func bounce() -> void:
	velocity.y = JUMP_VELOCITY * 0.85
	is_jumping = true
	_stomp_grace = 0.2


## Caiu num buraco: perde um coração e volta ao último checkpoint.
func fall_into_void() -> void:
	if _dead or _frozen:
		return
	GameState.damage(1)
	if GameState.hp <= 0:
		die()
		return
	Audio.play("hurt")
	GameState.register_fall()
	global_position = GameState.checkpoint_pos if GameState.has_checkpoint else spawn_point
	velocity = Vector2.ZERO
	_invincible = INVINCIBLE_TIME
	camera.reset_smoothing()


func die() -> void:
	if _dead:
		return
	_dead = true
	animation.visible = true
	GameState.register_death()
	Audio.play("death")
	# Adiado: trocar de cena dentro de um callback de física gera erro.
	get_tree().change_scene_to_file.call_deferred("res://screens/game_over.tscn")


# --- Câmera ----------------------------------------------------------------
# A câmera fica adiantada para o lado em que o player está olhando,
# mostrando mais do que vem pela frente.
func _update_camera(delta: float) -> void:
	var target := facing * CAMERA_LOOK_AHEAD
	camera.offset.x = lerp(camera.offset.x, target, clamp(CAMERA_LOOK_AHEAD_SPEED * delta, 0.0, 1.0))


# Limita a câmera às bordas do mapa da fase (calculadas a partir do TileMap),
# para ela não mostrar fora do mapa nem travar em áreas acima de y=0.
func _fit_camera_to_level() -> void:
	var level := get_parent()
	if level == null:
		return
	var bounds := Rect2()
	var found := false
	for tm in level.find_children("*", "TileMap", true, false):
		var used: Rect2i = tm.get_used_rect()
		if used.size == Vector2i.ZERO:
			continue
		var half := Vector2(tm.tile_set.tile_size) / 2.0
		var top_left: Vector2 = tm.to_global(tm.map_to_local(used.position) - half)
		var bottom_right: Vector2 = tm.to_global(tm.map_to_local(used.end) - half)
		var rect := Rect2(top_left, Vector2.ZERO).expand(bottom_right)
		bounds = rect if not found else bounds.merge(rect)
		found = true
	if not found:
		return
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
	camera.reset_smoothing()


# Nuvem de poeira nos pés do player (fica parada no mundo enquanto ele se move).
func _spawn_dust() -> void:
	var level := get_parent()
	if level == null:
		return
	var dust := AnimatedSprite2D.new()
	dust.sprite_frames = _dust_frames
	dust.scale = Vector2(3, 3)
	var feet := collision.global_position.y + (collision.shape as RectangleShape2D).size.y / 2.0
	dust.global_position = Vector2(global_position.x, feet - 20)
	dust.z_index = 1
	level.add_child(dust)
	dust.animation_finished.connect(dust.queue_free)
	dust.play()


func _on_hurtbox_body_entered(body):
	pass # Replace with function body.
