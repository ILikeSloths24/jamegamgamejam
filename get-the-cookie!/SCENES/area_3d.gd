
extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.global_position = Vector3(16.04, 18.89, -31.4)
