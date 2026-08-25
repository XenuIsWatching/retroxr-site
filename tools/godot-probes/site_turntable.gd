## Turntable and close-up renders of props for the website's guide pages.
##
## Windowed, never --headless: the dummy renderer returns a blank image.
##
##   godot --path RetroXR --resolution 320x240 --position 20,20 \
##       res://Tools/prop_turntable.tscn -- --subject=composite_cable
##
## Omit --subject to render every one. Frames land in res://probe_out/site/<name>/.
## Throwaway — delete the .gd/.tscn/.uid once the clips are encoded.
extends Node

const OUT_ROOT := "res://probe_out/site"
const SIZE := Vector2i(960, 720)
const BACKDROP := Color(0.043, 0.059, 0.11)

## path   — scene to instantiate
## focus  — optional node-name prefixes; frames only those, for a panel close-up
## frames — 72 spins a full turn, 1 renders a single still
## elev   — camera height as a fraction of the framing radius
const SUBJECTS := {
	"ps1_console": {"model": "playstation", "elev": 0.50},
	"ps1_controller": {"path": "res://Scenes/Objects/controllers/playstation/ps1_controller.tscn"},
	"ps1_dualshock": {"path": "res://Scenes/Objects/controllers/playstation/ps1_dualshock.tscn"},
	"wiimote": {"path": "res://Scenes/Objects/controllers/wii/wiimote.tscn"},
	"nunchuk": {"path": "res://Scenes/Objects/controllers/wii/nunchuk.tscn"},
}

var _sv: SubViewport = null
var _pivot: Node3D = null
var _cam: Camera3D = null


func _ready() -> void:
	get_tree().create_timer(900.0).timeout.connect(func() -> void:
		print("[site] TIMEOUT")
		get_tree().quit(1))
	_run.call_deferred()


func _freeze_all(n: Node) -> void:
	if n is RigidBody3D:
		(n as RigidBody3D).freeze = true
	for c in n.get_children():
		_freeze_all(c)


func _accumulate(n: Node, acc: AABB, has: Array, focus: Array) -> AABB:
	var want := true
	if not focus.is_empty():
		want = false
		for pre in focus:
			if n.name.begins_with(pre):
				want = true
				break
	if want and n is MeshInstance3D and (n as MeshInstance3D).mesh != null \
			and (n as MeshInstance3D).is_visible_in_tree():
		var vi := n as MeshInstance3D
		var box: AABB = vi.get_aabb()
		var world := vi.global_transform
		for i in range(8):
			var c: Vector3 = world * (box.position + Vector3(
				box.size.x * float(i & 1),
				box.size.y * float((i >> 1) & 1),
				box.size.z * float((i >> 2) & 1)))
			if not has[0]:
				acc = AABB(c, Vector3.ZERO)
				has[0] = true
			else:
				acc = acc.expand(c)
	# A focused node's own children count as part of it.
	var sub_focus: Array = focus
	if want and not focus.is_empty():
		sub_focus = []
	for child in n.get_children():
		acc = _accumulate(child, acc, has, sub_focus)
	return acc


func _build_world() -> void:
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
	env.ambient_light_energy = 0.32
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.85
	var we := WorldEnvironment.new()
	we.environment = env
	_sv.add_child(we)

	var key := DirectionalLight3D.new()
	key.light_energy = 0.95
	key.rotation_degrees = Vector3(-42.0, 38.0, 0.0)
	key.shadow_enabled = true
	_sv.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.30
	fill.rotation_degrees = Vector3(-15.0, -125.0, 0.0)
	_sv.add_child(fill)

	_pivot = Node3D.new()
	_pivot.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_sv.add_child(_pivot)

	_cam = Camera3D.new()
	_cam.fov = 40.0
	_cam.near = 0.002
	_sv.add_child(_cam)
	_cam.current = true

	# Rides with the camera. A socket is a hole in a panel and the directional
	# key cannot reach into it; without this the input panel renders black.
	var lamp := OmniLight3D.new()
	lamp.light_energy = 1.6
	lamp.omni_range = 4.0
	lamp.position = Vector3(0.0, 0.10, 0.05)
	_cam.add_child(lamp)


func _shoot(name: String, spec: Dictionary) -> void:
	var node: Node = null
	if spec.has("model"):
		# A hardware model is a registry row, not a scene: the PlayStation shell is
		# built by a script off its GLB, so there is no .tscn to instantiate.
		var row := SystemModelRegistry.resolve(spec["model"], "")
		node = SystemModelRegistry.instantiate(row)
		if node == null:
			print("[site] %s: cannot build model %s" % [name, spec["model"]])
			return
	elif spec.has("mesh"):
		var m: Mesh = load(spec["mesh"])
		if m == null:
			print("[site] %s: cannot load mesh %s" % [name, spec["mesh"]])
			return
		var mi := MeshInstance3D.new()
		mi.mesh = m
		node = mi
	else:
		var packed: PackedScene = load(spec["path"])
		if packed == null:
			print("[site] %s: cannot load %s" % [name, spec["path"]])
			return
		node = packed.instantiate()
	_pivot.add_child(node)
	# Every body, not just the root. A prop's plugs are rigid bodies of their
	# own hanging on ropes; leaving them live let them fall out of frame between
	# the framing measurement and the render.
	_freeze_all(node)
	node.set("physics_interpolation_mode", Node.PHYSICS_INTERPOLATION_MODE_OFF)
	for i in range(120):
		await get_tree().process_frame
	_freeze_all(node)

	var focus: Array = spec.get("focus", [])
	var box := _accumulate(node, AABB(), [false], focus)
	if box.size == Vector3.ZERO and not focus.is_empty():
		print("[site] %s: focus matched nothing, falling back to whole scene" % name)
		box = _accumulate(node, AABB(), [false], [])
	if box.size == Vector3.ZERO:
		print("[site] %s: no visuals" % name)
		_pivot.remove_child(node)
		node.queue_free()
		return

	var centre := box.position + box.size * 0.5
	if node is Node3D:
		(node as Node3D).position -= centre

	var swept: float = Vector2(box.size.x, box.size.z).length() * 0.5
	var reach: float = maxf(maxf(swept, box.size.y * 0.5), 0.012)
	var radius: float = reach / tan(deg_to_rad(_cam.fov * 0.5)) * 1.15
	var elev: float = float(spec.get("elev", 0.42))

	_cam.position = Vector3(0.0, radius * elev, radius)
	_cam.look_at(Vector3.ZERO)
	_pivot.rotation.y = 0.0

	var want_size: Vector2i = spec.get("size", SIZE)
	if _sv.size != want_size:
		_sv.size = want_size
		for i in range(6):
			await get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("%s/%s" % [OUT_ROOT, name]))

	for i in range(12):
		await get_tree().process_frame

	var frames: int = int(spec.get("frames", 72))
	var yaw: float = deg_to_rad(float(spec.get("yaw", 0.0)))

	# Nothing but the turntable may move during the take. These props hang on
	# simulated cables that keep swinging after every body is frozen, and that
	# drift is what made the wrap back to frame 0 jump.
	var saved := 0
	for i in range(frames):
		var ang: float = yaw if frames == 1 else TAU * float(i) / float(frames)
		_cam.position = Vector3(sin(ang) * radius, radius * elev, cos(ang) * radius)
		_cam.look_at(Vector3.ZERO)
		# Two frames, not one: with a single await the grab could land before the
		# new transform had been pushed through.
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := _sv.get_texture().get_image()
		if img == null or img.is_empty():
			continue
		img.save_png("%s/%s/%s_%03d.png" % [OUT_ROOT, name, name, i])
		saved += 1

	print("[site] %-22s %d/%d  extent=%.3f m  radius=%.3f m"
		% [name, saved, frames, box.size.length(), radius])

	_pivot.remove_child(node)
	node.queue_free()
	await get_tree().process_frame


func _run() -> void:
	_build_world()
	await get_tree().process_frame

	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--subject="):
			only = a.substr("--subject=".length())

	for name in SUBJECTS:
		if only != "" and name != only:
			continue
		await _shoot(name, SUBJECTS[name])

	print("[site] done")
	get_tree().quit(0)
