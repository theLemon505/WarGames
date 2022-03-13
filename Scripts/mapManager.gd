extends Spatial

export(Array, PackedScene) var maps
export var player_spawnable: PackedScene

var map

func _ready():
	Network.connect("client_left", self, "_on_client_disconnect")
	Network.connect("spawn_item", self, "_on_item_spawn")
	Network.connect("delete_item", self, "_on_item_delete")
	Network.connect("room_update", self, "_on_room_update")
	map = maps[rand_range(0, maps.size() - 1)].instance()
	add_child(map)
	for client in Network.room_clients:
		var player = player_spawnable.instance()
		if client != Network.client_id:
			player.name = client
			player.find_node("Camera", true).current = false
			player.find_node("Player", true).active = false
			set_vis(player, true)
		else:
			set_vis(player, false)
		map.add_child(player)

func set_vis(player, is_self):
	player.find_node("Circle", true).visible = is_self
	player.find_node("Sphere", true).visible = is_self

func _on_client_disconnect(id):
	if get_child(1).get_node(id) != null:
		var client =  get_child(1).get_node(id)
		client.queue_free()

func _on_item_delete(name):
	if get_tree().current_scene.has_node(name):
		get_tree().current_scene.get_node(name).queue_free()

func _on_item_spawn(namen, path, meta):
	if !get_tree().current_scene.has_node(namen):
		var node:RigidBody = load(path).instance()
		node.name = namen
		if meta.has("position"):
			var pos = meta["position"]
			node.transform.origin = Vector3(pos["x"], pos["y"], pos["z"])
			get_tree().current_scene.add_child(node)

func _on_room_update(data):
	for key in data.keys():
		if key != Network.client_id and key != Network.room_id and get_child(1).has_node(key):
			if data[key].has("position"):
				var dat = data[key]
				if get_child(1).has_node(key):
					var play = get_child(1).get_node(key)
					var head = play.get_child(0).get_child(0).get_child(1)
					var pos = dat["position"]
					var rot = dat["rotation"]
					if data[key].has("animation"):
						if play.get_child(0).find_node("AnimationPlayer", true) != null:
							play.get_child(0).find_node("AnimationPlayer", true).play(dat["animation"])
							if dat.has("animation") and head.get_child(0).get_child(1).has_animation(dat["head-animation"]):
								head.get_child(0).get_child(1).play(dat["head-animation"])
							play.get_child(0).pos = Vector3(pos["x"], pos["y"], pos["z"])
							play.get_child(0).rot = Vector3(rot["x"], rot["y"], rot["z"])
