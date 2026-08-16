## Stills of the handheld stand-ins with their SYSTEM controls in view, plus the
## screen-space position of each one so callouts can be drawn exactly rather
## than eyeballed off a grid.
##
##   godot --path RetroXR --resolution 320x240 --position 20,20 \
##       res://Tools/handheld_controls_shot.tscn
##
## Prints "[hc] <device> yaw=<n> <node> px=(x,y) front=<bool>" per target.
extends Node

const OUT := "res://probe_out/handheld_controls"
const SIZE := Vector2i(2000, 1500)
const BACKDROP := Color(0.043, 0.059, 0.11)

## device -> [scene, [target node names]]
const DEVICES := {
	"psp": ["res://Scenes/Objects/system_models/psp_primitive.tscn",
		["PowerSwitch", "OpenSlider", "VolumeDown", "VolumeUp", "PowerLED"]],
	"nds": ["res://Scenes/Objects/system_models/nds_primitive.tscn",
		["VolumeSlider", "Power Light", "CardSlotMouth"]],
	"n3ds": ["res://Scenes/Objects/system_models/n3ds_primitive.tscn",
		["Slider3D", "VolumeSlider", "PowerButton3ds"]],
}

## Yaws to try, in degrees around the device.
const YAWS := [20.0, 110.0]

var _sv: SubViewport = null
var _pivot: Node3D = null
var _cam: Camera3D = null


func _ready() -> void:
	get_tree().create_timer(400.0).timeout.connect(func() -> void:
		print("[hc] TIMEOUT")
		get_tree().quit(1))
	_run.call_deferred()


func _freeze_all(n: Node) -> void:
	if n is RigidBody3D:
		(n as RigidBody3D).freeze = true
	for c in n.get_children():
		_freeze_all(c)


func _find(n: Node, want: String) -> Node:
	if n.name == want:
		return n
	for c in n.get_children():
		var f := _find(c, want)
		if f != null:
			return f
	return null


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


func _world() -> void:
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
	env.ambient_light_energy = 0.36
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.78
	var we := WorldEnvironment.new()
	we.environment = env
	_sv.add_child(we)

	var key := DirectionalLight3D.new()
	key.light_energy = 0.9
	key.rotation_degrees = Vector3(-40.0, 35.0, 0.0)
	key.shadow_enabled = true
	_sv.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.35
	fill.rotation_degrees = Vector3(-12.0, -130.0, 0.0)
	_sv.add_child(fill)

	_pivot = Node3D.new()
	_pivot.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_sv.add_child(_pivot)

	_cam = Camera3D.new()
	_cam.fov = 34.0
	_cam.near = 0.002
	_sv.add_child(_cam)
	var lamp := OmniLight3D.new()
	lamp.light_energy = 0.5
	lamp.omni_range = 2.0
	_cam.add_child(lamp)
	_cam.current = true


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_world()
	await get_tree().process_frame

	for dev in DEVICES:
		var spec: Array = DEVICES[dev]
		var node: Node = load(spec[0]).instantiate()
		_pivot.add_child(node)
		_freeze_all(node)
		node.set("physics_interpolation_mode", Node.PHYSICS_INTERPOLATION_MODE_OFF)
		for i in range(60):
			await get_tree().process_frame
		_freeze_all(node)

		var box := _bounds(node, AABB(), [false])
		var centre := box.position + box.size * 0.5
		var reach: float = maxf(Vector2(box.size.x, box.size.z).length() * 0.5,
			box.size.y * 0.5)
		var radius: float = reach / tan(deg_to_rad(_cam.fov * 0.5)) * 1.10

		for yaw_deg: float in YAWS:
			var a := deg_to_rad(yaw_deg)
			_cam.position = centre + Vector3(sin(a) * radius, radius * 0.55, cos(a) * radius)
			_cam.look_at(centre)
			for i in range(8):
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			await get_tree().process_frame

			var img := _sv.get_texture().get_image()
			var fname := "%s_y%03d" % [dev, int(yaw_deg)]
			img.save_png("%s/%s.png" % [OUT, fname])

			for target: String in spec[1]:
				var t := _find(node, target) as Node3D
				if t == null:
					print("[hc] %s %s MISSING" % [dev, target])
					continue
				var p: Vector3 = t.global_position
				var behind := _cam.is_position_behind(p)
				var px: Vector2 = _cam.unproject_position(p)
				print("[hc] %-5s yaw=%3d %-16s px=(%4d,%4d) front=%s"
					% [dev, int(yaw_deg), target, int(px.x), int(px.y), str(not behind)])

		_pivot.remove_child(node)
		node.queue_free()
		await get_tree().process_frame

	print("[hc] done")
	get_tree().quit(0)
