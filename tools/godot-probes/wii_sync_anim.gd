## Renders the Wii Remote's battery cover swinging open to reveal SYNC.
##
## Windowed, never --headless.
##
##   godot --path RetroXR --resolution 320x240 --position 20,20 \
##       res://Tools/wii_sync_anim.tscn -- --dir=-1
##
## Frames land in res://probe_out/wii_sync/. Throwaway.
extends Node

const OUT := "res://probe_out/wii_sync"
const SIZE := Vector2i(960, 720)
const BACKDROP := Color(0.043, 0.059, 0.11)
const WIIMOTE := "res://Scenes/Objects/controllers/wii/wiimote.tscn"

## The hinge's own limits, from wiimote.tscn, and the angle at which the script
## re-activates the SYNC button.
const MAX_DEG := 105.0
const UNLOCK_DEG := 45.0

const OPEN := 44     ## frames spent swinging open
const HOLD := 26     ## frames held open, so the loop reads as a pause

var _sv: SubViewport = null


func _ready() -> void:
	get_tree().create_timer(300.0).timeout.connect(func() -> void:
		print("[sync] TIMEOUT")
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


func _bounds(n: Node, acc: AABB, has: Array) -> AABB:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null \
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
	for c in n.get_children():
		acc = _bounds(c, acc, has)
	return acc


func _run() -> void:
	var dir := 1.0
	for a in OS.get_cmdline_user_args():
		if a == "--dir=-1":
			dir = -1.0

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
	env.ambient_light_energy = 0.22
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.5
	var we := WorldEnvironment.new()
	we.environment = env
	_sv.add_child(we)

	var key := DirectionalLight3D.new()
	key.light_energy = 0.75
	key.rotation_degrees = Vector3(-38.0, 34.0, 0.0)
	key.shadow_enabled = true
	_sv.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.32
	fill.rotation_degrees = Vector3(-15.0, -125.0, 0.0)
	_sv.add_child(fill)

	var remote: Node = load(WIIMOTE).instantiate()
	_sv.add_child(remote)
	_freeze_all(remote)
	for i in range(30):
		await get_tree().process_frame
	_freeze_all(remote)

	var pivot := _find(remote, "CoverPivot") as Node3D
	var sync_btn := _find(remote, "SyncButton") as Node3D
	if pivot == null:
		print("[sync] no CoverPivot")
		get_tree().quit(1)
		return
	print("[sync] pivot at %v  sync at %v"
		% [pivot.global_position, sync_btn.global_position if sync_btn else Vector3.ZERO])

	for nm in ["CoverMesh", "ExpansionPort", "Body", "PortRecess"]:
		var n2 := _find(remote, nm)
		if n2 is Node3D:
			var b2 := _bounds(n2, AABB(), [false])
			print("[sync]   %-14s pos=%v  aabb pos=%v size=%v"
				% [nm, (n2 as Node3D).global_position, b2.position, b2.size])

	# The cover and SYNC are on the remote's underside, so the camera looks up at
	# its belly rather than down at the buttons.
	var target: Vector3 = sync_btn.global_position if sync_btn != null else pivot.global_position
	var box := _bounds(remote, AABB(), [false])
	var span: float = maxf(box.size.length() * 0.28, 0.05)

	var cam := Camera3D.new()
	cam.fov = 36.0
	cam.near = 0.001
	_sv.add_child(cam)
	var lamp := OmniLight3D.new()
	lamp.light_energy = 0.25
	lamp.omni_range = 0.5
	cam.add_child(lamp)
	# Mostly from below. The cover is a 2 mm plate at y -0.0175 sitting under a
	# SYNC cap at y -0.016, so it only occludes the button from underneath — an
	# oblique view sees straight past the plate and the cover looks decorative.
	var look := Vector3(0.0, -0.016, 0.040)
	cam.position = look + Vector3(0.075, -0.145, 0.045)
	cam.look_at(look)
	cam.current = true

	# The SYNC cap is white plastic on a white shell and vanishes into it under
	# any lighting. Tinted for the render only, so the reveal is legible — the
	# caption on the site says it is highlighted.
	var cap := _find(sync_btn, "ButtonMesh") as MeshInstance3D
	if cap != null:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.176, 0.890, 0.655)
		m.emission_enabled = true
		m.emission = Color(0.176, 0.890, 0.655)
		m.emission_energy_multiplier = 0.55
		cap.set_surface_override_material(0, m)
		print("[sync] cap tinted for legibility")
	else:
		print("[sync] no ButtonMesh under SyncButton")

	for i in range(10):
		await get_tree().process_frame

	var total := OPEN + HOLD
	var saved := 0
	for i in range(total):
		var t: float = 1.0
		if i < OPEN:
			var u := float(i) / float(OPEN - 1)
			t = 1.0 - pow(1.0 - u, 2.0)
		var deg := MAX_DEG * t
		pivot.rotation.x = deg_to_rad(deg * dir)
		# Drive the remote's own gate rather than just the transform: SYNC is
		# de-activated (and hidden) until the cover passes UNLOCK_DEG, and that
		# only happens through this callback. Rotating the pivot alone left the
		# button invisible for the whole clip.
		if remote.has_method("_on_cover_moved"):
			remote.call("_on_cover_moved", deg)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := _sv.get_texture().get_image()
		if img == null or img.is_empty():
			continue
		img.save_png("%s/sync_%03d.png" % [OUT, i])
		saved += 1

	print("[sync] saved %d/%d frames, dir=%.0f, unlock at %.0f deg"
		% [saved, total, dir, UNLOCK_DEG])
	get_tree().quit(0)
