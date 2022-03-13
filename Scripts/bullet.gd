extends RigidBody

var source = false
var tick = 4
var poss = Vector3.ZERO

func _ready():
	Network.connect("update_item", self, "_on_item_update")
	Network.connect("delete_item", self, "_on_item_delete")
	var vector = global_transform.origin
	if source:
		name = "bullet" + str(rand_range(0, 200))
		poss = vector
		if Network.socket.get_connection_status() == WebSocketClient.CONNECTION_CONNECTED:
			Network.send({"contact":"server", "type":"spawn","roomId":Network.room_id,"name":self.name,"path":"res://Assets/Weapons/Bullet.tscn", "meta":{"position":{"x":vector.x, "y":vector.y, "z":vector.z}}})
	else:
		mode = MODE_STATIC
		collision_layer = 6
	$Area.connect("body_entered", self, "_on_collision")

func _on_item_update(name, meta):
	if !source:
		if name == self.name:
			if meta.has("position"):
				var pos = meta["position"]
				poss = Vector3(pos["x"], pos["y"], pos["z"])

func _process(delta):
	tick -= 1
	var vector = global_transform.origin
	if source and tick <= 0 and Network.socket.get_connection_status() == WebSocketClient.CONNECTION_CONNECTED:
		Network.send({"contact":"server","type":"update-item","name":self.name,"roomId":Network.room_id, "meta":{"position":{"x":vector.x,"y":vector.y,"z":vector.z}}})
		tick = 4
	elif !source:
		global_transform.origin = global_transform.origin.linear_interpolate(poss, delta * 7)

func _on_item_delete(name):
	if name == self.name:
		queue_free()

func _on_timeout():
	print('test')
	if source:
		queue_free()

func _on_collision(body):
	if body is RigidBody:
		if "health" in body:
			body.health -= 10
		$AudioStreamPlayer.play()
		if source:
			$Control/AnimationPlayer.play("hit")
		body.add_torque(linear_velocity.rotated(Vector3(0,1,0), rad2deg(-90)))
	$Particles.emitting = true
	$MeshInstance.visible = false
	if source:
		var t = Timer.new()
		t.set_wait_time(1)
		t.set_one_shot(true)
		self.add_child(t)
		t.start()
		yield(t, "timeout")
		queue_free()
