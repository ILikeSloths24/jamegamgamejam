extends CharacterBody3D
@export var gravity: float = 9.8
@export var speed: float = 2.0
@export var sprint_speed: float = 4.0
@export var mouse_sensitivity: float = 0.003
@onready var camera: Camera3D = $Camera3D
@export var jump_velocity: float = 5.0
var held_object: Node3D = null
var camera_pitch: float = 0.0

func _unhandled_input(event):
	if event.is_action_pressed("interact"):
		if held_object == null:
			pick_up_object()
		else:
			drop_object()

	if event.is_action_pressed("attach_object"):
		attach_object()

func pick_up_object():
	var objects = $PickupArea.get_overlapping_bodies()

	for object in objects:
		if object.is_in_group("pickupable"):
			if object is RigidBody3D:
				held_object = object
				held_object.freeze = true

				held_object.get_parent().remove_child(held_object)
				$Camera3D/HoldPoint.add_child(held_object)

				held_object.position = Vector3.ZERO
				held_object.rotation_degrees = Vector3(0, 90, 0)
				return

func drop_object():
	if held_object != null:
		var object = held_object
		var drop_position = $Camera3D/HoldPoint.global_position

		$Camera3D/HoldPoint.remove_child(object)
		get_tree().current_scene.add_child(object)

		object.global_position = drop_position
		object.freeze = false

		held_object = null

func attach_object():
	if held_object == null:
		print("Pick up a book first!")
		return

	var nearby_bodies = $PickupArea.get_overlapping_bodies()
	var target: PhysicsBody3D = null

	for body in nearby_bodies:
		if body == held_object:
			continue

		if body is PhysicsBody3D:
			var distance = held_object.global_position.distance_to(
				body.global_position
			)

			if distance < 5:
				target = body
				break

	if target == null:
		print("No nearby object to attach to!")
		return

	var book = held_object
	var saved_transform = book.global_transform

	held_object = null
	$Camera3D/HoldPoint.remove_child(book)
	get_tree().current_scene.add_child(book)
	book.global_transform = saved_transform
	book.freeze = false

	var joint = Generic6DOFJoint3D.new()
	get_tree().current_scene.add_child(joint)

	joint.global_position = (
		book.global_position + target.global_position
	) / 2.0

	joint.node_a = joint.get_path_to(book)
	joint.node_b = joint.get_path_to(target)

	print("Objects connected!")

	if held_object == null:
		print("Pick up a book first!")
		return

	if target == null:
		print("No nearby object to attach to!")
		return


	$Camera3D/HoldPoint.remove_child(book)
	get_tree().current_scene.add_child(book)
	book.global_position = $Camera3D/HoldPoint.global_position
	book.freeze = false
	held_object = null

	get_tree().current_scene.add_child(joint)

	joint.global_position = (
		book.global_position + target.global_position
	) / 2.0


	joint.node_a = joint.get_path_to(book)
	joint.node_b = joint.get_path_to(target)

	print("Objects connected!")
	
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	var input_direction = Vector2.ZERO

	if Input.is_action_pressed("move_forward"):
		input_direction.y -= 1

	if Input.is_action_pressed("move_backward"):
		input_direction.y += 1

	if Input.is_action_pressed("move_left"):
		input_direction.x -= 1

	if Input.is_action_pressed("move_right"):
		input_direction.x += 1

	input_direction = input_direction.normalized()

	var direction = transform.basis * Vector3(input_direction.x, 0, input_direction.y)

	var current_speed = speed

	if Input.is_key_pressed(KEY_SHIFT):
		current_speed = sprint_speed

	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()

	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()
func _input(event):
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			rotate_y(-event.relative.x * mouse_sensitivity)

			camera_pitch -= event.relative.y * mouse_sensitivity
			camera_pitch = clamp(camera_pitch, -1.2, 1.2)

			camera.rotation.x = camera_pitch
	move_and_slide()
