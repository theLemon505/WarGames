extends RigidBody

export var block: PackedScene = preload("res://Assets/Prototype/Block.tscn")
export var player_path: NodePath

onready var player = get_node(player_path)

func _ready():
	if player != null:
		lock()

func _input(event):
	if player != null:
		transform.origin = player.find_node("hand", true).transform.origin
		transform.basis = player.find_node("hand", true).transform.basis
	if event.is_action_pressed("action"):
		grapple()
		
func grapple():
	if player.find_node("RayCast", true) != null:
		var ray: RayCast = player.find_node("RayCast", true) 
		if ray.is_colliding():
			var line: StaticBody = block.instance()
			get_parent().add_child(line)
			line.transform.looking_at(transform.origin, Vector3.UP)
			line.transform.origin = Vector3(lerp(transform.origin.x, ray.get_collision_point().x, 0.5),lerp(transform.origin.y, ray.get_collision_point().y, 0.5),lerp(transform.origin.z, ray.get_collision_point().z, 0.5))

func lock():
	axis_lock_linear_x = true
	axis_lock_linear_y = true
	axis_lock_linear_z = true
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
