extends Node

var ready_button
var ready = false
export var game_scene:PackedScene

func _ready():
	Network.connect("lobbied", self, "_on_lobbied")
	Network.connect("start_game", self, "_on_game_started")
	$Wait.hide()

func _on_join_pressed():
	var data = {"contact":"server", "type":"join-lobby", "username":Network.username, "name":$Start/LineEdit.text}
	Network.send(data)

func _on_create_pressed():
	var data = {"contact":"server", "type":"create-lobby", "username":Network.username, "name":$Start/LineEdit.text}
	Network.send(data)

func _on_lobbied():
	$Start.hide()
	for n in $Wait.get_children():
		$Wait.remove_child(n)
		n.queue_free()
	for client in Network.lobby_clients:
		var container = load("res://Assets/Graphics/2D/UI/user.tscn").instance()
		$Wait.add_child(container)
		container.get_child(0).text = client["username"]
		container.get_child(1).disabled = true
		if client["ready"] == true:
			container.get_child(1).text = "ready"
		if client["ready"] == false:
			container.get_child(1).text = "not ready"
	ready_button = Button.new()
	ready_button.connect("button_down", self, "_on_ready_toggled")
	$Wait.add_child(ready_button)
	$Wait.show()
	
func _on_game_started():
	var game = game_scene.instance()
	get_tree().get_root().add_child(game)
	get_tree().current_scene = game
	queue_free()

func _on_ready_toggled():
	if ready:
		ready = false
		ready_button.text = "ready up"
	elif !ready:
		ready = true
		ready_button.text = "unready"
	Network.send({"contact":"server", "type":"set-ready", "ready":ready})
