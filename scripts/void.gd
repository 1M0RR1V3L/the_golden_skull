extends Area2D
## Área de morte embaixo dos buracos: o player perde um coração e volta ao
## último checkpoint; inimigos que caírem somem.


func _on_body_entered(body):
	if body.is_in_group("player"):
		body.fall_into_void.call_deferred()
	elif body is EnemyBase:
		body.queue_free()
