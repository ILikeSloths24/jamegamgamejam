extends CharacterBody3D

@export var gravity: float = 9.8
@export var speed: float = 2.0
@export var sprint_speed: float = 4.0
@export var mouse_sensitivity: float = 0.003
@export var jump_velocity: float = 5.0

@onready var camera: Camera3D = $Camera3D
@onready var hold_point: Marker3D = $Camera3D/HoldPoint
@onready var pickup_area: Area3D = $PickupArea

var held_object: RigidBody3D = null
var camera_pitch: float = 0.0


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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


func _unhandled_input(event):
	if event.is_action_pressed("interact"):
		if held_object == null:
			pick_up_object()
		else:
			drop_object()

	if event.is_action_pressed("attach_object"):
		attach_object()


func pick_up_object():
	var objects = pickup_area.get_overlapping_bodies()

	for object in objects:
		if object is RigidBody3D and object.is_in_group("pickupable"):
			held_object = object

			# Stop physics while the object is held.
			held_object.freeze = true
			held_object.linear_velocity = Vector3.ZERO
			held_object.angular_velocity = Vector3.ZERO

			# Reparent it to the hold point.
			held_object.get_parent().remove_child(held_object)
			hold_point.add_child(held_object)

			# Position it in front of the camera.
			held_object.position = Vector3.ZERO
			held_object.rotation = Vector3.ZERO
			return

	print("No pickupable object nearby!")


func drop_object():
	if held_object == null:
		return

	var object = held_object
	var saved_transform = object.global_transform

	held_object = null

	hold_point.remove_child(object)
	get_tree().current_scene.add_child(object)

	object.global_transform = saved_transform
	object.freeze = false


func attach_object():
	if held_object == null:
		print("Pick up an object first!")
		return

	var nearby_bodies = pickup_area.get_overlapping_bodies()
	var target: PhysicsBody3D = null

	for body in nearby_bodies:
		if body == held_object:
			continue

		if body is PhysicsBody3D:
			if body.is_in_group("pickupable"):
				target = body
				break

	if target == null:
		print("No nearby target object!")
		return

	var object = held_object

	# Save its position before removing it from the grip.
	var saved_transform = object.global_transform

	# Clear the player's grip.
	held_object = null

	# Remove it from the camera's HoldPoint.
	hold_point.remove_child(object)

	# Attach it to the target object.
	get_tree().current_scene.add_child(object)
	object.global_transform = saved_transform

	# Stop physics from moving it.
	object.freeze = true
	object.linear_velocity = Vector3.ZERO
	object.angular_velocity = Vector3.ZERO

	print("Object permanently attached!")

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

	var direction = transform.basis * Vector3(
		input_direction.x, 0, input_direction.y
	)

	var current_speed = speed

	if Input.is_key_pressed(KEY_SHIFT):
		current_speed = sprint_speed

	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()
