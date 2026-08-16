## NES stills for the website: front with the flap shut, front with it open on
## the cartridge bay, and the rear connector panel.
##
##   godot --path RetroXR --resolution 320x240 --position 20,20 \
##       res://Tools/nes_shots.tscn
extends Node

const OUT := "res://probe_out/nes"
const SIZE := Vector2i(2000, 1500)
const BACKDROP := Color(0.043, 0.059, 0.11)
const MODEL := "res://Scenes/Objects/system_models/nes_primitive.tscn"
const MODEL_ALT := "res://imported-assets/consoles/nes/nes_console.glb"

var _sv: SubViewport = null
var _model: Node = null


func _ready() -> void:
	get_tree().create_timer(300.0).timeout.connect(func() -> void:
		print("[nes] TIMEOUT")
		get_tree().quit(1))
	_run.call_deferred()


func _freeze_all(n: Node) -> void:
	if n is RigidBody3D:
		var rb := n as RigidBody3D
		rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		rb.freeze = true
	for c in n.get_children():
		_freeze_all(c)


func _bounds(n: Node, acc: AABB, has: Array) -> AABB:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null \
			and (n as MeshInstance3D).is_visible_in_tree():
		var vi := n as MeshInstance3D
		var box: AABB = vi.get_aabb()
		var w := vi.global_transform
		for i in range(8):
			var c: Vector3 = w * (box.position + Vector3(
				box.size.x * float(i & 1), box.size.y * float((i >> 1) & 1),
				box.size.z * float((i >> 2) & 1)))
			if not has[0]:
				acc = AABB(c, Vector3.ZERO)
				has[0] = true
			else:
				acc = acc.expand(c)
	for c in n.get_children():
		acc = _bounds(c, acc, has)
	return acc


func _shot(name: String, yaw_deg: float, elev: float, pad: float) -> void:
	var box := _bounds(_model, AABB(), [false])
	var centre := box.position + box.size * 0.5
	var reach: float = maxf(Vector2(box.size.x, box.size.z).length() * 0.5, box.size.y * 0.5)
	var cam := _sv.get_node_or_null("Cam") as Camera3D
	var dist: float = reach / tan(deg_to_rad(cam.fov * 0.5)) * pad
	var yaw := deg_to_rad(yaw_deg)
	cam.position = centre + Vector3(sin(yaw) * dist, dist * elev, cos(yaw) * dist)
	cam.look_at(centre)
	for i in range(10):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	var img := _sv.get_texture().get_image()
	img.save_png("%s/%s.png" % [OUT, name])
	print("[nes] %-16s yaw=%.0f  %dx%d" % [name, yaw_deg, img.get_width(), img.get_height()])


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	_sv = SubViewport.new()
	_sv.size = SIZE
	_sv.own_world_3d = true
	_sv.msaa_3d = Viewport.MSAA_4X
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sv)

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.42, 0.47, 0.56)
	sky_mat.sky_horizon_color = Color(0.62, 0.64, 0.68)
	sky_mat.ground_bottom_color = Color(0.16, 0.16, 0.18)
	sky_mat.ground_horizon_color = Color(0.30, 0.30, 0.33)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BACKDROP
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.ambient_light_energy = 0.34
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.75
	var we := WorldEnvironment.new()
	we.environment = env
	_sv.add_child(we)

	var key := DirectionalLight3D.new()
	key.light_energy = 0.95
	key.rotation_degrees = Vector3(-40.0, 35.0, 0.0)
	key.shadow_enabled = true
	_sv.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.35
	fill.rotation_degrees = Vector3(-12.0, -130.0, 0.0)
	_sv.add_child(fill)

	var cam := Camera3D.new()
	cam.name = "Cam"
	cam.fov = 36.0
	cam.near = 0.002
	_sv.add_child(cam)
	var lamp := OmniLight3D.new()
	lamp.light_energy = 0.5
	lamp.omni_range = 2.0
	cam.add_child(lamp)
	cam.current = true

	# The NES model is the GLB with nes_model.gd attached at spawn time — see
	# model_registry.gd, which pairs a "script" with a "requires" GLB. Setting it
	# before the node enters the tree is what lets _ready build the flap, the RF
	# panel and the ports.
	_model = load(MODEL_ALT).instantiate()
	var script: Script = load("res://Scripts/Objects/system_models/nes_model.gd")
	_model.set_script(script)
	var path := MODEL_ALT
	_sv.add_child(_model)
	_freeze_all(_model)
	for i in range(40):
		await get_tree().process_frame
	_freeze_all(_model)
	print("[nes] loaded %s" % path)

	var has_lid: bool = _model.has_method("set_lid_angle_deg")
	print("[nes] lid api: %s" % str(has_lid))

	await _shot("nes_front", 25.0, 0.42, 1.18)
	await _shot("nes_back", 200.0, 0.30, 1.18)

	if has_lid:
		_model.call("set_lid_angle_deg", 105.0)
		for i in range(20):
			await get_tree().process_frame
		await _shot("nes_open", 20.0, 0.55, 1.15)
		_model.call("set_lid_angle_deg", -105.0)
		for i in range(20):
			await get_tree().process_frame
		await _shot("nes_open_neg", 20.0, 0.55, 1.15)

	print("[nes] done")
	get_tree().quit(0)
