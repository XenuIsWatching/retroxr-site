## The Wii's rear face with BOTH sockets seated, for the website's Wii page.
##
## The sensor bar socket is built in the model's own _ready, but the AV Multi Out
## is seated by the cabinet through configure_av_ports() — so a bare model shows
## a labelled panel with nothing in the AV cutout. This does what the cabinet
## does.
##
##   godot --path RetroXR --resolution 320x240 --position 20,20 \
##       res://Tools/wii_back_shot.tscn
extends Node

const OUT := "res://probe_out/wii_back"
const SIZE := Vector2i(2000, 1500)
const BACKDROP := Color(0.043, 0.059, 0.11)
const MODEL := "res://Scenes/Objects/system_models/wii_primitive.tscn"
const AV_PORT := "res://Scenes/Objects/system_models/wii/wii_av_port.tscn"


func _ready() -> void:
	get_tree().create_timer(240.0).timeout.connect(func() -> void:
		print("[back] TIMEOUT")
		get_tree().quit(1))
	_run.call_deferred()


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


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	var sv := SubViewport.new()
	sv.size = SIZE
	sv.own_world_3d = true
	sv.msaa_3d = Viewport.MSAA_4X
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sv)

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
	env.ambient_light_energy = 0.30
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.62
	var we := WorldEnvironment.new()
	we.environment = env
	sv.add_child(we)

	var key := DirectionalLight3D.new()
	key.light_energy = 0.85
	key.rotation_degrees = Vector3(-35.0, 200.0, 0.0)
	key.shadow_enabled = true
	sv.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.35
	fill.rotation_degrees = Vector3(-10.0, 150.0, 0.0)
	sv.add_child(fill)

	var model: Node = load(MODEL).instantiate()
	sv.add_child(model)
	for i in range(20):
		await get_tree().process_frame

	# What the cabinet does: hand the model its AV port so it can seat it on the
	# AvSeat marker with the right basis.
	var port: Node = load(AV_PORT).instantiate()
	sv.add_child(port)
	if model.has_method("configure_av_ports"):
		model.call("configure_av_ports", [port])
		print("[back] AV Multi Out seated")
	else:
		print("[back] model has no configure_av_ports")
	for i in range(12):
		await get_tree().process_frame

	var back := model.get_node_or_null("Back") as Node3D
	var box := _bounds(back if back != null else model, AABB(), [false])
	var centre := box.position + box.size * 0.5
	print("[back] panel centre %v  size %v" % [centre, box.size])

	var cam := Camera3D.new()
	cam.fov = 34.0
	cam.near = 0.001
	sv.add_child(cam)
	var lamp := OmniLight3D.new()
	lamp.light_energy = 0.45
	lamp.omni_range = 0.8
	cam.add_child(lamp)
	# Square on to the panel, from behind the console (-Z of the model's back).
	var reach: float = maxf(box.size.x, box.size.y) * 0.5 + 0.012
	var dist: float = reach / tan(deg_to_rad(cam.fov * 0.5)) * 1.15
	cam.position = centre + Vector3(0.0, dist * 0.22, -dist)
	cam.look_at(centre)
	cam.current = true

	for i in range(12):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame

	var img := sv.get_texture().get_image()
	img.save_png("%s/wii_back.png" % OUT)
	print("[back] saved %dx%d" % [img.get_width(), img.get_height()])
	get_tree().quit(0)
