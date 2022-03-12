extends Control

export var edit_scene: PackedScene
export var game_scene: PackedScene
export var lobby_scene: PackedScene

func _ready():
	Network.connect("failed", self, "_on_failed")
	Network.connect("connected", self, "_on_connected")
	Network.connect_to_server()

func _on_edit_pressed():
	var edit = edit_scene.instance()
	get_tree().get_root().add_child(edit)
	get_tree().current_scene = edit
	queue_free()

func _on_play_pressed():
	var game = game_scene.instance()
	get_tree().get_root().add_child(game)
	get_tree().current_scene = game
	queue_free()


func _on_sensitivity_changed(value):
	Settings.sensitivity = value

func _on_failed():
	$Label5.text = "server status: not connected"

func _on_connected():
	$Label5.text = "server status: connected"

func _on_online_pressed():
	var lobby = lobby_scene.instance()
	get_tree().get_root().add_child(lobby)
	get_tree().current_scene = lobby
	queue_free()


func _on_username_changed(new_text):
	Network.username = new_text
