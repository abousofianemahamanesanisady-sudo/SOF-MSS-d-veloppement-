extends Node3D
## MS FAMILY WORLD — playable vertical slice.
## Fictional family-friendly neighborhood; Android touch controls + keyboard fallback.

var player: CharacterBody3D
var car: CharacterBody3D
var driving := false
var mission_done := false
var mission_stage := 0
var speed := 0.0
var hud: Label
var mission_label: Label
var hint_label: Label
var joystick := Vector2.ZERO
var touch_origin := Vector2.ZERO
var joystick_touch := -1
var action_button: Button
var drive_button: Button

const WALK_SPEED := 5.0
const DRIVE_SPEED := 18.0

func _ready() -> void:
	_build_world()
	_build_player()
	_build_car()
	_build_ui()
	_spawn_residents()
	_update_mission()

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var world_env := Environment.new()
	world_env.background_mode = Environment.BG_SKY
	world_env.sky = Sky.new()
	world_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world_env.ambient_light_color = Color(0.72, 0.78, 0.88)
	world_env.ambient_light_energy = 0.8
	env.environment = world_env
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.25
	add_child(sun)

	_box("Terrain", Vector3(0, -0.35, 0), Vector3(100, 0.6, 100), Color(0.25, 0.48, 0.25))
	_box("Main road", Vector3(0, -0.02, 0), Vector3(12, 0.12, 100), Color(0.13, 0.14, 0.16))
	_box("Cross road", Vector3(0, 0.0, -18), Vector3(100, 0.13, 9), Color(0.13, 0.14, 0.16))
	for z in range(-45, 46, 8):
		_box("Road marking", Vector3(0, 0.07, z), Vector3(0.22, 0.025, 3.4), Color(0.95, 0.9, 0.68))
	_box("Sidewalk left", Vector3(-7.2, 0.05, 0), Vector3(2.3, 0.3, 100), Color(0.55, 0.55, 0.52))
	_box("Sidewalk right", Vector3(7.2, 0.05, 0), Vector3(2.3, 0.3, 100), Color(0.55, 0.55, 0.52))

	_house(Vector3(-16, 0, -9), Color(0.82, 0.66, 0.48), "Maison familiale")
	_house(Vector3(17, 0, -5), Color(0.72, 0.78, 0.84), "Maison des voisins")
	_house(Vector3(-19, 0, 20), Color(0.78, 0.72, 0.57), "Petite villa")
	for p in [Vector3(-13,0,-20), Vector3(14,0,-22), Vector3(-15,0,28), Vector3(20,0,24), Vector3(28,0,4)]:
		_tree(p)

func _box(n: String, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = n
	body.position = pos
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	col.shape = s
	body.add_child(col)
	add_child(body)
	return body

func _house(pos: Vector3, color: Color, label: String) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	_mesh_box(root, Vector3(0, 2, 0), Vector3(9, 4, 8), color)
	_mesh_box(root, Vector3(0, 4.35, 0), Vector3(9.8, 0.7, 8.8), Color(0.28, 0.19, 0.16))
	_mesh_box(root, Vector3(0, 1.15, 4.06), Vector3(1.5, 2.3, 0.12), Color(0.25, 0.15, 0.1))
	_mesh_box(root, Vector3(-2.6, 2.4, 4.08), Vector3(1.5, 1.2, 0.12), Color(0.35, 0.65, 0.8))
	_mesh_box(root, Vector3(2.6, 2.4, 4.08), Vector3(1.5, 1.2, 0.12), Color(0.35, 0.65, 0.8))
	var area := Area3D.new()
	area.position = Vector3(0, 1, 5.2)
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 3.2
	cs.shape = sh
	area.add_child(cs)
	root.add_child(area)
	area.body_entered.connect(func(b): if b == player and hint_label: hint_label.text = "Bienvenue près de : " + label)

func _mesh_box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	parent.add_child(mi)

func _tree(pos: Vector3) -> void:
	var trunk := _mesh_box_node("Tronc", pos + Vector3(0,1.1,0), Vector3(0.55,2.2,0.55), Color(0.3,0.19,0.1))
	var crown := _mesh_box_node("Feuillage", pos + Vector3(0,3.0,0), Vector3(2.7,2.8,2.7), Color(0.13,0.38,0.17))

func _mesh_box_node(n: String, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.position = pos
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	add_child(mi)
	return mi

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Joueur"
	player.position = Vector3(2, 1, 8)
	add_child(player)
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	var mi := MeshInstance3D.new()
	mi.mesh = capsule
	mi.position.y = 0.9
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.38, 0.85)
	mi.material_override = mat
	player.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := CapsuleShape3D.new()
	sh.radius = 0.42
	sh.height = 1.8
	cs.shape = sh
	player.add_child(cs)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 4.3, 7.5)
	camera.rotation_degrees.x = -19
	camera.current = true
	player.add_child(camera)

func _build_car() -> void:
	car = CharacterBody3D.new()
	car.name = "Voiture familiale"
	car.position = Vector3(3.5, 0.75, 1)
	add_child(car)
	_mesh_box(car, Vector3(0,0.55,0), Vector3(2.1,0.8,4.1), Color(0.75,0.12,0.08))
	_mesh_box(car, Vector3(0,1.12,-0.2), Vector3(1.7,0.65,1.8), Color(0.18,0.28,0.34))
	for x in [-1.05,1.05]:
		for z in [-1.3,1.3]:
			var wheel := _mesh_box_node("Roue", Vector3(x,0.3,z), Vector3(0.38,0.65,0.75), Color(0.06,0.06,0.06))
			car.add_child(wheel)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(2.1,1.5,4.1)
	cs.shape = sh
	car.add_child(cs)

func _spawn_residents() -> void:
	for i in range(4):
		var npc := Node3D.new()
		npc.name = "Voisin_" + str(i+1)
		npc.position = Vector3(-10 + i*6, 0.9, -5 - (i%2)*8)
		add_child(npc)
		var mesh := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.38
		capsule.height = 1.7
		mesh.mesh = capsule
		var mat := StandardMaterial3D.new()
		mat.albedo_color = [Color(0.8,0.55,0.3),Color(0.2,0.6,0.35),Color(0.65,0.3,0.65),Color(0.85,0.75,0.45)][i]
		mesh.material_override = mat
		mesh.position.y = 0.0
		npc.add_child(mesh)
		var label := Label3D.new()
		label.text = ["Amina","Moussa","Samira","Idrissa"][i]
		label.position.y = 1.3
		label.font_size = 36
		npc.add_child(label)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 16)
	panel.custom_minimum_size = Vector2(380, 110)
	layer.add_child(panel)
	var vb := VBoxContainer.new()
	panel.add_child(vb)
	hud = Label.new()
	hud.text = "MS FAMILY WORLD  |  Prototype 0.1"
	vb.add_child(hud)
	mission_label = Label.new()
	vb.add_child(mission_label)
	hint_label = Label.new()
	hint_label.text = "Explore le quartier. Rejoins la maison familiale."
	vb.add_child(hint_label)

	var help := Label.new()
	help.text = "Mobile : joystick gauche • boutons à droite\nPC : ZQSD / flèches • E pour interagir"
	help.position = Vector2(18, 138)
	layer.add_child(help)

	var interact := Button.new()
	interact.text = "INTERAGIR"
	interact.position = Vector2(1050, 560)
	interact.size = Vector2(190, 64)
	interact.pressed.connect(_interact)
	layer.add_child(interact)
	action_button = interact

	var drive := Button.new()
	drive.text = "MONTER / DESCENDRE"
	drive.position = Vector2(1000, 635)
	drive.size = Vector2(240, 58)
	drive.pressed.connect(_toggle_drive)
	layer.add_child(drive)
	drive_button = drive

func _update_mission() -> void:
	if mission_done:
		mission_label.text = "Mission terminée : le quartier est à toi !"
	elif mission_stage == 0:
		mission_label.text = "Mission : retrouve la maison familiale (vers le nord-ouest)."
	else:
		mission_label.text = "Mission : rapporte-toi près de la voiture rouge."

func _interact() -> void:
	if driving:
		return
	if mission_stage == 0 and player.global_position.distance_to(Vector3(-16,0,-9)) < 9:
		mission_stage = 1
		hint_label.text = "Maison retrouvée ! Va maintenant voir la voiture rouge."
	elif mission_stage == 1 and player.global_position.distance_to(car.global_position) < 5:
		mission_done = true
		hint_label.text = "Bravo ! Mission familiale accomplie."
	else:
		hint_label.text = "Continue l'exploration et approche-toi des lieux importants."
	_update_mission()

func _toggle_drive() -> void:
	if not driving and player.global_position.distance_to(car.global_position) < 5:
		driving = true
		player.visible = false
		player.set_physics_process(false)
		hint_label.text = "Tu conduis. Appuie sur MONTER / DESCENDRE pour sortir."
	elif driving:
		driving = false
		player.global_position = car.global_position + car.global_transform.basis.x * 2.0
		player.visible = true
		player.set_physics_process(true)
		speed = 0.0
		hint_label.text = "Tu es sorti du véhicule."

func _physics_process(delta: float) -> void:
	if driving:
		var throttle := Input.get_axis("ui_up", "ui_down")
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_Z): throttle = 1.0
		if Input.is_key_pressed(KEY_S): throttle = -1.0
		var steer := Input.get_axis("ui_left", "ui_right")
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_Q): steer = -1.0
		if Input.is_key_pressed(KEY_D): steer = 1.0
		speed = move_toward(speed, throttle * DRIVE_SPEED, 12.0 * delta)
		car.rotate_y(-steer * delta * clamp(abs(speed)/5.0,0.0,1.0))
		car.velocity = -car.global_transform.basis.z * speed
		car.move_and_slide()
		hud.text = "MS FAMILY WORLD  |  Vitesse : " + str(round(abs(speed)*5)) + " km/h"
	else:
		var input_dir := Vector2.ZERO
		input_dir.x = Input.get_axis("ui_left","ui_right")
		input_dir.y = Input.get_axis("ui_up","ui_down")
		if Input.is_key_pressed(KEY_Z): input_dir.y = -1
		if Input.is_key_pressed(KEY_S): input_dir.y = 1
		if Input.is_key_pressed(KEY_Q): input_dir.x = -1
		if Input.is_key_pressed(KEY_D): input_dir.x = 1
		input_dir += joystick
		input_dir = input_dir.limit_length(1.0)
		var direction := Vector3(input_dir.x,0,input_dir.y)
		player.velocity.x = direction.x * WALK_SPEED
		player.velocity.z = direction.z * WALK_SPEED
		player.velocity.y -= 20.0 * delta
		player.move_and_slide()
		hud.text = "MS FAMILY WORLD  |  Exploration"
	if Input.is_key_pressed(KEY_E):
		_interact()
	if Input.is_key_pressed(KEY_F):
		_toggle_drive()
