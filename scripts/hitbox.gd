extends Area2D
## Área em cima do inimigo: o player pisa, quica e causa dano.
## Só conta como pisão se o player está caindo e com os pés acima da cabeça
## do inimigo (encostar de lado ou o inimigo cair em cima não é pisão).


func _on_body_entered(body):
	if not body.is_in_group("player") or not owner.has_method("stomped"):
		return
	var falling: bool = body.velocity.y > 0.0
	var feet_above: bool = body.feet_y() <= global_position.y + 14.0
	if falling and feet_above:
		body.bounce()
		owner.stomped(body)
