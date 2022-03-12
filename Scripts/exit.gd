extends Button

export var scene: NodePath

func _ready():
	connect("pressed", self, "_on_exit")

func _on_exit():
	change_scene()

func change_scene():
	if ResourceLoader.exists("res://Scenes/Menu.tscn"):
		get_tree().change_scene("res://Scenes/Menu.tscn")
