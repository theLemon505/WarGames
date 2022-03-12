extends Spatial

export var gun_path: NodePath
export(Array, NodePath) var button_paths

onready var buttons: Array
onready var gun = get_node(gun_path)

var inputVector = Vector2.ZERO
var data = {}

func _ready():
	var file2Check = File.new()
	var doFileExists = file2Check.file_exists("weapon_data.json")
	for button_path in button_paths:
		var index = button_paths.find(button_path, 0)
		buttons.append(0)
		buttons[index] = get_node(button_path)
	if doFileExists:
		load_data()
	for button in buttons:
		button.connect("edited", self, "_on_edited")
	
func _on_edited():
	toggle_active()
	
func _input(event):
	if event is InputEventMouseMotion and Input.is_action_pressed("action"):
		inputVector += (event.relative / 360) * 0.75
		inputVector.y = clamp(inputVector.y, deg2rad(-90), deg2rad(90))
		
func set_rot(anglex, angley):
	var qued = gun.transform.basis.get_rotation_quat()
	gun.global_transform.basis = Basis(Quat(Vector3(0, anglex+deg2rad(90), angley))).scaled(gun.global_transform.basis.get_scale())

func reset_rot():
	inputVector = Vector2.ZERO
	var qued = gun.transform.basis.get_rotation_quat()
	gun.global_transform.basis = Basis(Quat(Vector3(0, deg2rad(90), 0))).scaled(gun.global_transform.basis.get_scale())

func _process(delta):
	if Input.is_action_pressed("action"):
		set_rot(inputVector.x, inputVector.y)
	else:
		reset_rot()
		
func save():
	pass

func toggle_active():
	toggle_all_on()
	for button in buttons:
		if button.active_item != null:
			if gun.find_node(button.active_item, true) != null:
				var item = gun.find_node(button.active_item, true)
				data[item.name] = true
				item.transform.origin = Vector3.ZERO
				item.visible = true
	save_data()

func load_data():
	var file = File.new()
	file.open("weapon_data.json", file.READ)
	var text = file.get_as_text()
	var json = parse_json(text)
	data = json
	set_vals()
	set_vars()

func clear_vars():
	for dat in data:
		if dat.ends_with("settings"):
			print("test")
			dat = {"ammo":0, "recoil":0, "accuracy":0, "aim":70}
	print("cleared")

func set_vars():
	clear_vars()
	for button in buttons:
		var item = gun.find_node(button.active_item, true)
		if item != null:
			data[item.name + "_settings"] = {"ammo":item.ammo, "recoil":item.recoil, "accuracy":item.accuracy, "aim":item.aim} 

func set_vals():
	for dat in data.keys():
		if gun.find_node(dat, true) != null:
			var item = gun.find_node(dat, true)
			item.transform.origin = Vector3.ZERO
			item.visible = data[dat]
		for button in buttons:
			for item in button.items:
				if item == dat:
					if data[dat] == true:
						button.active_item = item

func save_data():
	set_vals()
	set_vars()
	var file = File.new()
	file.open("weapon_data.json", File.WRITE)
	file.store_string(to_json(data))
	file.close()

func toggle_all_on():
	for node in gun.find_node("pain_base").get_children():
		if node.name == "base":
			node.visible = true
		else:
			data[node.name] = false
			node.visible = false
	
