## Turntable renders of the Wii hardware for the website's platform page.
##
## Windowed, never --headless: the dummy renderer returns a blank image, so this
## draws into a SubViewport on the real GPU and saves one PNG per step.
##
##   godot --path RetroXR --resolution 320x240 --position 20,20 \
##       res://Tools/wii_turntable.tscn -- --subject=console
##
## Omit --subject to render every one. Frames land in res://probe_out/wii/<name>/.
## Throwaway — delete the .gd/.tscn/.uid once the clips are encoded.
extends Node

const OUT_ROOT := "res://probe_out/wii"
const FRAMES := 72
const SIZE := Vector2i(960, 720)

## Backdrop matches the site's ink so the clips sit on the page rather than in a
## bright card. The sky stays as the reflection source — these shells are
## clearcoat and read entirely through their reflections.
const BACKDROP := Color(0.043, 0.059, 0.11)

const SUBJECTS := {
	"console": "res://Scenes/Objects/system_models/wii_primitive.tscn",
	"wiimote": "res://Scenes/Objects/controllers/wii/wiimote.tscn",
	"motion_plus": "res://Scenes/Objects/controllers/wii/motion_plus.tscn",
	"nunchuk": "res://Scenes/Objects/controllers/wii/nunchuk.tscn",
	"sensor_bar": "res://Scenes/Objects/system_models/wii/sensor_bar.tscn",
}

var _sv: SubViewport = null
var _pivot: Node3D = null
var _cam: Camera3D = null


func _ready() -> void:
	get_tree().create_timer(600.0).timeout.connect(func() -> void:
		print("[wii] TIMEOUT")
		get_tree().quit(1))
	_run.call_deferred()


## World-space bounds of every visual under `n`, so the camera can frame a
## subject it was not hand-tuned for.
func _bounds(n: Node, acc: AABB, has: Array) -> AABB:
	# MeshInstance3D only, and only what is actually drawn. Counting every
	# VisualInstance3D pulled in snap zones and cable rigs whose bounds dwarf the
	# shell, which framed a 45 mm dongle as if it were a third of a metre.
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null \
			and (n as MeshInstance3D).is_visible_in_tree():
		var vi := n as MeshInstance3D
		var box: AABB = vi.get_aabb()
		var world := vi.global_transform
		var corners: Array[Vector3] = []
		for i in range(8):
			corners.append(world * (box.position + Vector3(
				box.size.x * float(i & 1),
				box.size.y * float((i >> 1) & 1),
				box.size.z * float((i >> 2) & 1))))
		for c in corners:
			if not has[0]:
				acc = AABB(c, Vector3.ZERO)
				has[0] = true
			else:
				acc = acc.expand(c)
	for child in n.get_children():
		acc = _bounds(child, acc, has)
	return acc


func _build_world() -> void:
	_sv = SubViewport.new()
	_sv.size = SIZE
	_sv.own_world_3d = true
	_sv.transparent_bg = false
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
	env.ambient_light_energy = 0.30
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
	fill.light_energy = 0.28
	fill.rotation_degrees = Vector3(-15.0, -125.0, 0.0)
	_sv.add_child(fill)

	_pivot = Node3D.new()
	_sv.add_child(_pivot)

	_cam = Camera3D.new()
	_cam.fov = 40.0
	_cam.near = 0.005
	_sv.add_child(_cam)
	_cam.current = true


func _clear_pivot() -> void:
	for c in _pivot.get_children():
		_pivot.remove_child(c)
		c.queue_free()
	await get_tree().process_frame


func _shoot(name: String, path: String) -> void:
	var packed: PackedScene = load(path)
	if packed == null:
		print("[wii] %s: cannot load %s" % [name, path])
		return

	var node: Node = packed.instantiate()
	if node is RigidBody3D:
		(node as RigidBody3D).freeze = true
	_pivot.add_child(node)
	for i in range(20):
		await get_tree().process_frame

	var box := _bounds(node, AABB(), [false])
	if box.size == Vector3.ZERO:
		print("[wii] %s: no visuals found" % name)
		await _clear_pivot()
		return

	# Centre the subject on the pivot so it spins about itself, then frame it by
	# its longest horizontal extent — these range from a 45 mm dongle to a 215 mm
	# console and no single hand-set radius covers both.
	var centre := box.position + box.size * 0.5
	if node is Node3D:
		(node as Node3D).position -= centre
	# Frame on the swept radius: the subject turns, so the widest it ever gets is
	# its horizontal diagonal, not whichever face happens to face frame 0.
	var swept: float = Vector2(box.size.x, box.size.z).length() * 0.5
	var reach: float = maxf(maxf(swept, box.size.y * 0.5), 0.015)
	var radius: float = reach / tan(deg_to_rad(_cam.fov * 0.5)) * 1.15

	_cam.position = Vector3(0.0, radius * 0.42, radius)
	_cam.look_at(Vector3.ZERO)

	var dir := ProjectSettings.globalize_path("%s/%s" % [OUT_ROOT, name])
	DirAccess.make_dir_recursive_absolute(dir)

	for i in range(12):
		await get_tree().process_frame

	var saved := 0
	for i in range(FRAMES):
		_pivot.rotation.y = TAU * float(i) / float(FRAMES)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := _sv.get_texture().get_image()
		if img == null or img.is_empty():
			continue
		img.save_png("%s/%s/%s_%03d.png" % [OUT_ROOT, name, name, i])
		saved += 1

	print("[wii] %-12s %d/%d frames  extent=%.3f m  radius=%.3f m"
		% [name, saved, FRAMES, box.size.length(), radius])
	await _clear_pivot()


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

	print("[wii] done")
	get_tree().quit(0)
