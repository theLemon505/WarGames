extends RigidBody

func _ready():
	$Timer.connect("timeout", self, "_on_timeout")
	$Area.connect("body_entered", self, "_on_collision")
	name = str(get_parent().get_child_count())
	var vector = linear_velocity

func _on_timeout():
	queue_free()

func _on_collision(body):
	if body is RigidBody:
		$AudioStreamPlayer.play()
		$Control/AnimationPlayer.play("hit")
		body.add_torque(linear_velocity.rotated(Vector3(0,1,0), rad2deg(-90)))
	$Particles.emitting = true
	$MeshInstance.visible = false
	var t = Timer.new()
	t.set_wait_time(1)
	t.set_one_shot(true)
	self.add_child(t)
	t.start()
	yield(t, "timeout")
	queue_free()
