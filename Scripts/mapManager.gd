extends Spatial

export(Array, PackedScene) var maps
export var player_spawnable: PackedScene

var map

func _ready():
	Network.connect("client_left", self, "_on_client_disconnect")
	Network.connect("room_update", self, "_on_room_update")
	map = maps[rand_range(0, maps.size() - 1)].instance()
	add_child(map)
	print(Network.client_id)
	for client in Network.room_clients:
		print(client)
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

func _on_room_update(data):
	for key in data.keys():
		if key != Network.client_id and key != Network.room_id and get_child(1).get_node(key) != null:
			if data[key].has("position"):
				var dat = data[key]
				var play = get_child(1).get_node(key)
				var head = play.get_child(0).get_child(0).get_child(1)
				var pos = dat["position"]
				var rot = dat["rotation"]
				if data[key].has("animation"):
					play.get_child(0).find_node("AnimationPlayer", true).play(dat["animation"])
					if dat.has("animation") and head.get_child(0).get_child(1).has_animation(dat["head-animation"]):
						head.get_child(0).get_child(1).play(dat["head-animation"])
				play.get_child(0).pos = Vector3(pos["x"], pos["y"], pos["z"])
				play.get_child(0).rot = Vector3(rot["x"], rot["y"], rot["z"])
