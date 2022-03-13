extends RigidBody

export var player_path: NodePath
export var aim_lerp = 30
export var bullet = preload("res://Assets/Weapons/Bullet.tscn")
export var fire_rate: float = 7
export var burst = false

var accuracy = 10
var ammo = 0
var recoil = 1
var aim = 70
var camera
var reloading = false
var set = false

onready var real_ammo = ammo

onready var player = get_node(player_path)
onready var hand = player.find_node("hand", true)
onready var raycast = player.find_node("RayCast", true)

var data = {}
var ok = true

func _ready():
	Network.connect("room_update", self, "_on_room_update")
	if is_instance_valid(player) and player.active:
		load_data()
		real_ammo = ammo
		$Control/HBoxContainer/Label.text = str(real_ammo) + "/" + str(ammo)
	else:
		$Control/HBoxContainer/Label.hide()
		real_ammo = ammo
	if is_instance_valid(hand):
		axis_lock_angular_x = true
		axis_lock_angular_y = true
		axis_lock_angular_z = true
		axis_lock_linear_x = true
		axis_lock_linear_y = true
		axis_lock_linear_z = true
		global_transform.origin = hand.global_transform.origin
		rotation = hand.global_transform.basis.get_euler()
		camera = player.find_node("Camera")

func _on_room_update(data):
	if set == false:
		for key in data.keys():
			if is_instance_valid(player) and key == player.get_parent().name:
				var dat = data[key]
				dat = dat["gun"]
				self.data = dat
				set_vals()
				set = true

func _process(delta):
	if is_instance_valid(hand):
		global_transform.origin.x = lerp(global_transform.origin.x, hand.global_transform.origin.x, delta * 45)
		global_transform.origin.y = lerp(global_transform.origin.y, hand.global_transform.origin.y, delta * 45)
		global_transform.origin.z = lerp(global_transform.origin.z, hand.global_transform.origin.z, delta * 45)
		rotation.x = lerp(rotation.x, hand.global_transform.basis.get_euler().x, delta * aim_lerp)
		rotation.y = lerp_angle(rotation.y, hand.global_transform.basis.get_euler().y, delta * aim_lerp)
		rotation.z = lerp(rotation.z, hand.global_transform.basis.get_euler().z, delta * aim_lerp)
		if player.active:
			if Input.is_action_pressed("aim"):
				camera.fov = lerp(camera.fov, aim, delta * 10)
			if Input.is_action_just_pressed("reload") and !Input.is_action_pressed("aim") and !Input.is_action_pressed("crouch"):
				reload()
			if Input.is_action_pressed("action") and ok and !reloading:
				shoot()

func reload():
	reloading = true
	var o = Timer.new()
	o.set_wait_time(1)
	o.set_one_shot(true)
	self.add_child(o)
	o.start()
	yield(o, "timeout")
	ok = true
	real_ammo = ammo
	$Control/HBoxContainer/Label.text = str(real_ammo) + "/" + str(ammo)
	reloading = false
	o.queue_free()

func load_data():
	var file = File.new()
	file.open("weapon_data.json", file.READ)
	var text = file.get_as_text()
	var json = parse_json(text)
	data = json
	set_vals()

func shoot():
	if real_ammo > 0:
		$pain_base/Position3D/CPUParticles.emitting = true
		player.find_node("CameraAnimator", true).play("shake")
		if burst:
			return
		else:
			$AudioStreamPlayer3D.play()
			camera.get_parent().transform = camera.get_parent().transform.rotated(Vector3(1,0,0).rotated(Vector3(0,1,0), camera.global_transform.basis.get_euler().y), deg2rad(0.1 + recoil))
			var b = bullet.instance()
			b.source = true
			b.global_transform.origin = $pain_base/Position3D.global_transform.origin
			get_tree().current_scene.add_child(b)
			var direction
			if raycast.is_colliding():
				direction = ((raycast.get_collision_point() + Vector3(rand_range(-accuracy, accuracy), rand_range(-accuracy, accuracy), 0)) - $pain_base/Position3D.global_transform.origin).normalized()
			else:
				direction = (((-raycast.global_transform.basis.z * 50) + Vector3(rand_range(-accuracy, accuracy), rand_range(-accuracy, accuracy), 0)) - $pain_base/Position3D.global_transform.origin).normalized()
			b.add_central_force(direction * 500)
			b.look_at(b.linear_velocity, Vector3.UP)
			b.transform.basis.scaled(Vector3(1,1,b.linear_velocity.length()))
			transform.origin += transform.basis.z * 0.1 * recoil
			ok = false
			real_ammo -= 1
			var o = Timer.new()
			o.set_wait_time(fire_rate)
			o.set_one_shot(true)
			self.add_child(o)
			o.start()
			yield(o, "timeout")
			ok = true
			o.queue_free()
			var t = Timer.new()
			t.set_wait_time(1)
			t.set_one_shot(true)
			self.add_child(t)
			t.start()
			$Control/HBoxContainer/Label.text = str(real_ammo) + "/" + str(ammo)
			yield(t, "timeout")
			$pain_base/Position3D/CPUParticles.emitting = false
			t.queue_free()

func set_vals():
	for dat in data.keys():
		var d = data[dat]
		if data[dat.split("_settings")[0]] == true:
			if typeof(d) != TYPE_BOOL:
				if d.has("aim") and d["aim"] != 70:
					print(d["aim"])
					aim = d["aim"]
				if d.has("accuracy") and d["accuracy"] != 0:
					accuracy /= d["accuracy"]
				if d.has("ammo") and d["ammo"] != 0:
					ammo = d["ammo"]
				if d.has("recoil") and d["recoil"] != 0:
					recoil -= d["recoil"]
		if find_node(dat, true) != null:
			var item = find_node(dat, true)
			item.transform.origin = Vector3.ZERO
			item.visible = data[dat]
