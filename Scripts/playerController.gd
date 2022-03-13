extends RigidBody

onready var head: MeshInstance = $bot/Sphere

export var acceleration = 15
export var speed = 10
export var jump_force = 25

var pos = Vector3.ZERO
var rot = Vector3.ZERO
var timer = 5
var active = true
var vector = Vector3.ZERO
var inputVector = Vector2.ZERO
var act_speed = 0
var mouse_state = false

func _ready():
	if active and Network.socket.get_connection_status() == WebSocketClient.CONNECTION_CONNECTED:
		var file = File.new()
		file.open("weapon_data.json", file.READ)
		var text = file.get_as_text()
		var json = parse_json(text)
		Network.send({"contact":"server","type":"set-meta","meta":{"gun":json}})
		Network.send({"contact":"server","type":"update-room","roomId":Network.room_id})
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_state = false

func _input(event):
	if active:
		if event.is_action_pressed("escape") and mouse_state == false:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			mouse_state = true
		if event is InputEventMouseMotion:
			inputVector += (event.relative / 360) * Settings.sensitivity
			inputVector.y = clamp(inputVector.y, deg2rad(-90), deg2rad(90))
			set_rot(-inputVector.x, -inputVector.y)

func set_rot(anglex, angley):
	var qued = head.transform.basis.get_rotation_quat()
	head.global_transform.basis = Basis(Quat(Vector3(angley, anglex, 0))).scaled(head.global_transform.basis.get_scale())

func _integrate_forces(state):
	if active:
		if Input.is_action_pressed("jump") and $RayCast.is_colliding():
			linear_velocity.y = jump_force
		if Input.is_action_pressed("sprint") and vector.length() != 0:
			act_speed = acceleration * 2
		else:
			act_speed = acceleration
		if Input.is_action_pressed("crouch"):
			linear_velocity = linear_velocity
		else:
			linear_velocity.x = vector.x
			linear_velocity.z = vector.z
			if $RayCast.is_colliding():
				vector.x = clamp(vector.x, -act_speed, act_speed)
				vector.z = clamp(vector.z, -act_speed, act_speed)

func _process(delta):
	if active:
		timer -= 1
		if Input.is_action_pressed("aim"):
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			mouse_state = false
		
		var x = Input.get_action_strength("right") - Input.get_action_strength("left")
		var z = Input.get_action_strength("down") - Input.get_action_strength("up")
		
		if Input.is_action_just_pressed("sprint") and vector.length() != 0:
			$AudioStreamPlayer3D.playing = true
		if Input.is_action_just_released("sprint"):
			$AudioStreamPlayer3D.playing = false
		if Input.is_action_pressed("sprint") and vector.length() != 0:
			$bot/AnimationPlayer.play("sprint")
			act_speed = acceleration * 2
		elif Input.is_action_pressed("aim"):
			$bot/AnimationPlayer.play("aim")
		else:
			$bot/AnimationPlayer.play("RESET")
			act_speed = acceleration
		
		$bot/Sphere/Camera.fov = clamp(lerp($bot/Sphere/Camera.fov, linear_velocity.length() + 70, delta * 4), 70, 140)
		
		vector = Vector3(x, 0, z)
		vector *= act_speed
		vector = vector.rotated(Vector3(0,1,0), -inputVector.x)
		
		if Input.is_action_just_pressed("crouch"):
			add_central_force(transform.basis.z * 100)
		if Input.is_action_pressed("crouch"):
			$bot/AnimationPlayer.play("crouch")
		if timer <= 0 and Network.socket.get_connection_status() == WebSocketClient.CONNECTION_CONNECTED:
			Network.send({"contact":"server","type":"set-meta","meta":
				{"rotation":{"x":head.global_transform.basis.get_euler().x, "y":head.global_transform.basis.get_euler().y, "z":head.global_transform.basis.get_euler().z},
				"position":{"x":global_transform.origin.x, "y":global_transform.origin.y,"z":global_transform.origin.z},
				"animation":$bot/AnimationPlayer.current_animation,
				"head-animation":$bot/Sphere/Camera/CameraAnimator.current_animation}})
			Network.send({"contact":"server","type":"update-room","roomId":Network.room_id})
			timer = 5
	else:
		global_transform.origin = global_transform.origin.linear_interpolate(pos, delta * 2.5)
		var current_rot = Quat(head.global_transform.basis.get_rotation_quat())
		var target = Quat(rot)
		var smooth = current_rot.slerp(target, delta * 2.5)
		head.global_transform.basis = Basis(smooth)
