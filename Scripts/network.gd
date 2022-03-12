extends Node

var socket: WebSocketClient = WebSocketClient.new()
var client_id = ""
var room_id = ""
var lobby_clients = []
var room_clients = []
var username = ""
var active = true

signal connected
signal failed
signal start_game
signal lobbied
signal room_update
signal client_left

func _ready():
	socket.connect("data_received", self, "_on_data")
	socket.connect("connection_failed", self, "_on_kicked")
	socket.connect("connection_closed", self, "_on_disconnect")
	socket.connect("connection_established", self, "_on_connected")

var server = "ws://45.33.126.24:4040/"
var local = "ws://127.0.0.1:4040/"

func connect_to_server():
	var err = socket.connect_to_url(server)
	if err != OK:
		print("Unable to connect")
		set_process(false)

func send_to_room(message):
	message["id"] = client_id
	var data = {"contact":"room","roomId":room_id,"message":message}

func send(json_data):
	json_data["id"] = client_id
	socket.get_peer(1).put_packet(JSON.print(json_data).to_utf8())

func _on_connected(proto = ""):
	emit_signal("connected")

func _on_disconnect(was_clean = false):
	pass

func _on_kicked(was_clean = false):
	emit_signal("failed")

func spawn(parent, child, position, name):
	send({"contact":"server", "type":"spawn", "parent_path":parent, "position":{"x":position.x,"y":position.y,"z":position.z}, "roomId":Network.room_id,"name":name, "child_path":child})

func delete(node):
	send({"contact":"server", "roomId":Network.room_id, "type":"delete", "node_path":node})

func _process(delta):
	socket.poll()

func _on_data():
	var payload = JSON.parse(socket.get_peer(1).get_packet().get_string_from_utf8()).result
	if payload["type"] == "spawn":
		if payload["status"] == "good":
			var parent = get_node(payload["parent"])
			var child = load(payload["child"]).instance()
			child.name = payload["name"]
			var pos = payload["position"]
			child.transform.origin = Vector3(pos["x"], pos["y"], pos["z"])
			parent.add_child(child)
	if payload["type"] == "handshake":
		if payload["status"] == "good":
			client_id = payload["id"]
	if payload["type"] == "start":
		if payload["status"] == "good":
			var c = payload["clients"]
			print(c["clients"])
			room_clients = c["clients"]
			room_id = payload["roomId"]
			emit_signal("start_game")
	if payload["type"] == "remove":
		if payload["status"] == "good":
			emit_signal("client_left", payload["client"])
	if payload["type"] == "lobby":
		if payload["status"] == "good":
			lobby_clients = payload["clients"]
			emit_signal("lobbied")
		if payload["status"] == "bad":
			print("bad lobby request")
	if payload["type"] == "room":
		if payload["status"] == "good":
			emit_signal("room_update", payload["data"])
