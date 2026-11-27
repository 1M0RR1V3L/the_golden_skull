class_name SpriteUtil
## Utilitários para montar animações a partir das spritesheets (uma linha de quadros).


## Cria um SpriteFrames a partir de um dicionário:
##   { "nome": [textura, largura_do_quadro, fps, loop], ... }
static func frames_from_sheets(defs: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	for anim_name in defs:
		var d: Array = defs[anim_name]
		var tex: Texture2D = d[0]
		var w: int = d[1]
		var h: int = tex.get_height()
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, d[2])
		frames.set_animation_loop(anim_name, d[3])
		for i in int(tex.get_width() / w):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * w, 0, w, h)
			frames.add_frame(anim_name, atlas)
	return frames


## Primeiro quadro de uma spritesheet (para ícones).
static func first_frame(tex: Texture2D, w: int) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	atlas.region = Rect2(0, 0, w, tex.get_height())
	return atlas


## Efeito de "fumacinha" (Cloud_Poof) que se apaga sozinho.
static func spawn_poof(parent: Node, pos: Vector2, scale := 3.0) -> void:
	var fx := AnimatedSprite2D.new()
	fx.sprite_frames = frames_from_sheets({
		"poof": [preload("res://img/items_ui/Effects/Cloud_Poof (16 x 16).png"), 16, 16.0, false],
	})
	fx.scale = Vector2(scale, scale)
	fx.global_position = pos
	fx.z_index = 2
	parent.add_child(fx)
	fx.animation_finished.connect(fx.queue_free)
	fx.play("poof")


## Raycast para baixo a partir de "from"; devolve o ponto do chão ou null.
static func find_floor(node: Node2D, from: Vector2, max_dist := 600.0) -> Variant:
	var space := node.get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, max_dist), 2)
	var hit := space.intersect_ray(q)
	return hit.position if not hit.is_empty() else null
