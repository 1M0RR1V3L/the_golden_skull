extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	$sprite.play("collect")



func _on_sprite_animation_finished():
	get_tree().change_scene_to_file("res://screens/credits.tscn")
