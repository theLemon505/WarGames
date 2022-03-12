extends Control

export var game_scene: PackedScene

func _ready():
	var t = Timer.new()
	t.set_wait_time(7)
	t.set_one_shot(true)
	self.add_child(t)
	t.start()
	yield(t, "timeout")
	var game = game_scene.instance()
	get_tree().get_root().add_child(game)
	get_tree().current_scene = game
	queue_free()
