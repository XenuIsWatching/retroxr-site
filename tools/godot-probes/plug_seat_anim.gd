## Renders a composite plug being brought to a television's AV IN and seated.
##
## The seated pose is not guessed — the TV's own RcaPort is asked to take the
## plug, its resulting transform is recorded, and the animation interpolates
## back out along that pose's own axis. Guessing the mating axis by hand put the
## plug through the side of the socket.
##
##   godot --path RetroXR --resolution 320x240 --position 20,20 \
##       res://Tools/plug_seat_anim.tscn
##
## Frames land in res://probe_out/seat/. Throwaway.
extends Node

const OUT := "res://probe_out/seat"
const SIZE := Vector2i(960, 720)
const BACKDROP := Color(0.043, 0.059, 0.11)

const TV := "res://Scenes/Objects/tv.tscn"
const CABLE := "res://Scenes/Objects/cables/composite_cable.tscn"

const APPROACH := 46
const HOLD := 26
const TRAVEL := 0.085

var _sv: SubViewport = null


func _ready() -> void:
	get_tree().create_timer(300.0).timeout.connect(func() -> void:
		print("[seat] TIMEOUT")
		get_tree().quit(1))
	_run.call_deferred()


func _freeze_all(n: Node) -> void:
	if n is RigidBody3D:
		var rb := n as RigidBody3D
		rb.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		rb.freeze = true
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
	env.ambient_light_energy = 0.34
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	_sv.add_child(we)

	var key := DirectionalLight3D.new()
	key.light_energy = 0.9
	key.rotation_degrees = Vector3(-42.0, 38.0, 0.0)
	key.shadow_enabled = true
	_sv.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.30
	fill.rotation_degrees = Vector3(-15.0, -125.0, 0.0)
	_sv.add_child(fill)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_world()

	var tv: Node = load(TV).instantiate()
	_sv.add_child(tv)
	var cable: Node = load(CABLE).instantiate()
	_sv.add_child(cable)
	_freeze_all(tv)
	_freeze_all(cable)
	for i in range(30):
		await get_tree().process_frame
	_freeze_all(tv)
	_freeze_all(cable)

	var port := _find(tv, "CompositePort")
	var plug := _find(cable, "PlugA0")
	if port == null or plug == null:
		print("[seat] port=%s plug=%s — cannot continue" % [str(port), str(plug)])
		get_tree().quit(1)
		return

	# Let the game seat it, then read back where "seated" actually is.
	port.call("pick_up_object", plug)
	for i in range(6):
		await get_tree().process_frame
	var seated: Transform3D = (plug as Node3D).global_transform
	print("[seat] seated at %v" % seated.origin)

	# A snap zone re-takes anything released inside it, so the zone is switched
	# off before the plug is driven by hand.
	if port.has_method("drop_object"):
		port.call("drop_object")
	port.set("enabled", false)
	await get_tree().process_frame
	_freeze_all(cable)

	# Out along the socket's own axis — the plug's local -Z at rest.
	var out_dir := -seated.basis.z.normalized()

	var cam := Camera3D.new()
	cam.fov = 30.0
	cam.near = 0.001
	_sv.add_child(cam)
	var lamp := OmniLight3D.new()
	lamp.light_energy = 0.9
	lamp.omni_range = 1.2
	cam.add_child(lamp)

	var side := out_dir.cross(Vector3.UP).normalized()
	if side.length_squared() < 0.01:
		side = Vector3.RIGHT
	cam.position = seated.origin + out_dir * 0.16 + side * 0.14 + Vector3(0, 0.07, 0)
	cam.look_at(seated.origin + out_dir * TRAVEL * 0.35)
	cam.current = true

	for i in range(10):
		await get_tree().process_frame

	var total := APPROACH + HOLD
	var saved := 0
	for i in range(total):
		var t: float = 1.0
		if i < APPROACH:
			var u := float(i) / float(APPROACH - 1)
			t = 1.0 - pow(1.0 - u, 2.2)
		var tf := seated
		tf.origin = seated.origin + out_dir * lerpf(TRAVEL, 0.0, t)
		(plug as Node3D).global_transform = tf
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := _sv.get_texture().get_image()
		if img == null or img.is_empty():
			continue
		img.save_png("%s/seat_%03d.png" % [OUT, i])
		saved += 1

	print("[seat] saved %d/%d frames" % [saved, total])
	get_tree().quit(0)
