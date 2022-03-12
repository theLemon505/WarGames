extends Button

export(Array, String) var items
export var reliant = false
export var relied:NodePath

var active_item
var index = 0
var rel

signal edited

func _ready():
	if reliant:
		rel = get_node(relied)
		rel.connect("pressed", self, "_on_relied_node_changed")
	connect("pressed", self, "_on_item_change_pressed")
	if items.size() > 0:
		active_item = items[index]

func _on_relied_node_changed():
	if rel.active_item == "":
		active_item = ""
		emit_signal("edited")

func _on_item_change_pressed():
	if reliant:
		if rel.active_item != "":
			if items.size() > 0:
				if index < items.size() - 1:
					index += 1
				else:
					index = 0
				active_item = items[index]
				emit_signal("edited")
	else:
		if items.size() > 0:
			if index < items.size() - 1:
				index += 1
			else:
				index = 0
			active_item = items[index]
			emit_signal("edited")
