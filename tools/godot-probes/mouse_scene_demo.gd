## The room shot for the website's keyboard-and-mouse page: a CRT monitor with
## Monkey Island on it, and RetroXR's own grabbable mouse sliding across a desk
## in front of it.
##
## The picture is real — a tower running ScummVM, cabled to the monitor over
## VGA exactly as a player would. The mouse is the real RetroMouse object. What
## is scripted is the hand: the object is moved along the desk, and the travel it
## covers is converted to libretro deltas with the mouse's own sensitivity
## constant, which is what RetroMouse itself does when a hand carries it.
##
##   godot --path RetroXR --resolution 960x720 --position 20,20 \
##       res://Tools/mouse_scene_demo.tscn -- --boot=25 --skip=75 --shoot=14
##
## Frames land in res://probe_out/mouse_scene/. Throwaway.
extends Node3D

const OUT := "res://probe_out/mouse_scene"
const SIZE := Vector2i(1280, 720)

const TV_SCENE := preload("res://Scenes/Objects/tv.tscn")
const SYSTEM_SCENE := preload("res://Scenes/Objects/system.tscn")
const VGA_CABLE := preload("res://Scenes/Objects/cables/vga_cable.tscn")
const MOUSE_SCENE := preload("res://Scenes/Objects/peripherals/retro_mouse.tscn")
const KEYBOARD_SCENE := preload("res://Scenes/Objects/peripherals/retro_keyboard.tscn")

const RETROK_ESCAPE := 27
## RetroMouse.sensitivity: cursor units per metre of surface travel.
const SENSITIVITY := 2400.0
const DESK_Y := 0.78

var _boot := 25.0
var _skip := 75.0
var _shoot := 14.0

var _sv: SubViewport = null
var _sys: Node3D = null
var _lr: Node = null
var _mouse: Node3D = null
var _saved := 0


func _ready() -> void:
	get_tree().create_timer(500.0).timeout.connect(func() -> void:
		print("[scene] TIMEOUT")
		get_tree().quit(1))
	_run.call_deferred()


func _wait(sec: float) -> void:
	var t := 0.0
	while t < sec:
		await get_tree().process_frame
		t += get_process_delta_time()


func _frames(n: int) -> void:
	for i in range(n):
		await get_tree().process_frame


func _rom() -> String:
	var root := RomLibrary.default_roms_root().path_join("scummvm")
	var d := DirAccess.open(root)
	if d == null:
		return ""
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		if d.current_is_dir() and f.to_lower().contains("monkey"):
			var sub := DirAccess.open(root.path_join(f))
			sub.list_dir_begin()
			var g := sub.get_next()
			while g != "":
				if g.get_extension().to_lower() == "scummvm":
					return root.path_join(f).path_join(g)
				g = sub.get_next()
		f = d.get_next()
	return ""


func _tap_esc() -> void:
	if _lr == null:
		return
	_lr.call("SetKeyState", 0, RETROK_ESCAPE, true, 0)
	await _wait(0.08)
	_lr.call("SetKeyState", 0, RETROK_ESCAPE, false, 0)


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--boot="):
			_boot = float(a.substr(7))
		elif a.begins_with("--skip="):
			_skip = float(a.substr(7))
		elif a.begins_with("--shoot="):
			_shoot = float(a.substr(8))

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	var rom := _rom()
	if rom.is_empty():
		print("[scene] no Monkey Island under roms/scummvm")
		get_tree().quit(1)
		return

	_sv = SubViewport.new()
	_sv.size = SIZE
	_sv.own_world_3d = true
	_sv.msaa_3d = Viewport.MSAA_4X
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sv)

	# A dim room: the monitor should be the brightest thing in frame, the way a
	# CRT in a dark room actually is.
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.025, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.5, 0.65)
	env.ambient_light_energy = 0.60
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.85
	env.glow_enabled = true
	env.glow_intensity = 0.5
	var we := WorldEnvironment.new()
	we.environment = env
	_sv.add_child(we)

	# A soft light over the desk, so the mouse and keyboard are readable without
	# washing the monitor out.
	var deskLamp := OmniLight3D.new()
	deskLamp.light_energy = 1.5
	deskLamp.omni_range = 3.0
	deskLamp.position = Vector3(0.15, DESK_Y + 0.95, 0.75)
	_sv.add_child(deskLamp)

	var key := DirectionalLight3D.new()
	key.light_energy = 0.85
	key.rotation_degrees = Vector3(-48.0, 28.0, 0.0)
	key.shadow_enabled = true
	_sv.add_child(key)

	# The desk the mouse slides on. RetroMouse glues to a surface, and this is it.
	var desk := MeshInstance3D.new()
	var top := BoxMesh.new()
	top.size = Vector3(1.5, 0.04, 0.7)
	desk.mesh = top
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.22, 0.21, 0.25)
	dmat.roughness = 0.85
	desk.set_surface_override_material(0, dmat)
	desk.position = Vector3(0.0, DESK_Y - 0.02, 0.30)
	_sv.add_child(desk)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = top.size
	col.shape = box
	body.add_child(col)
	body.position = desk.position
	_sv.add_child(body)

	# Monitor: a CRT with a DE-15 and no phono row.
	var mon := TV_SCENE.instantiate() as RetroTV
	mon.tv_model = "crt_monitor"
	mon.freeze = true
	mon.position = Vector3(0.0, DESK_Y + 0.22, -0.28)
	_sv.add_child(mon)
	mon.add_to_group("spawned")

	# The machine: a tower running ScummVM.
	_sys = SYSTEM_SCENE.instantiate() as Node3D
	_sys.set("systemid", "scummvm")
	_sys.set("model_id", "pc_tower")
	_sys.set("rom_path", rom)
	_sys.set("freeze", true)
	_sys.position = Vector3(-0.95, 0.30, -0.20)
	_sv.add_child(_sys)
	_sys.add_to_group("spawned")
	await _frames(90)

	# VGA between them, seated the way a player seats it.
	var lead := VGA_CABLE.instantiate() as Node3D
	lead.position = Vector3(-0.4, DESK_Y + 0.1, -0.5)
	_sv.add_child(lead)
	await _frames(25)
	var a := _sys.find_child("VgaPort", true, false) as XRToolsSnapZone
	var b := mon.find_child("VgaPort", true, false) as XRToolsSnapZone
	if a != null and b != null:
		a.pick_up_object(lead.get_node("PlugA0"))
		b.pick_up_object(lead.get_node("PlugB0"))
		print("[scene] VGA seated")
	else:
		print("[scene] VGA ports missing: tower=%s monitor=%s" % [str(a), str(b)])
	await _frames(45)

	# The mouse, on the desk in front.
	var kb := KEYBOARD_SCENE.instantiate() as Node3D
	kb.position = Vector3(-0.16, DESK_Y + 0.02, 0.22)
	_sv.add_child(kb)
	await _frames(25)
	if kb is RigidBody3D:
		(kb as RigidBody3D).freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		(kb as RigidBody3D).freeze = true

	_mouse = MOUSE_SCENE.instantiate() as Node3D
	_mouse.position = Vector3(0.26, DESK_Y + 0.02, 0.38)
	_sv.add_child(_mouse)
	await _frames(30)
	if _mouse is RigidBody3D:
		(_mouse as RigidBody3D).freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		(_mouse as RigidBody3D).freeze = true

	_sys.call("power_on")
	print("[scene] powered on")

	_lr = _sys.find_child("Libretro", true, false)
	if _lr == null:
		print("[scene] no Libretro node under the system")
	else:
		_lr.call("SetControllerPortDevice", 0, 2)

	var cam := Camera3D.new()
	cam.fov = 38.0
	cam.near = 0.01
	_sv.add_child(cam)
	cam.position = Vector3(0.06, DESK_Y + 0.46, 1.12)
	cam.look_at(Vector3(0.0, DESK_Y + 0.14, 0.02))
	cam.current = true

	# Boot, then skip the opening.
	await _wait(_boot)
	var t := 0.0
	while t < _skip:
		await _tap_esc()
		await _wait(2.0)
		t += 2.1
	print("[scene] skip done, frames=%s"
		% (str(_lr.call("GetFrameCount")) if _lr != null else "?"))

	# Slide the mouse and report the travel, the way a held RetroMouse does.
	var elapsed := 0.0
	var phase := 0.0
	var prev: Vector3 = _mouse.position
	while elapsed < _shoot:
		var dt := get_process_delta_time()
		phase += dt * 0.85
		var p := Vector3(0.26 + cos(phase) * 0.13, DESK_Y + 0.02, 0.38 + sin(phase * 1.3) * 0.10)
		_mouse.position = p
		var travel := p - prev
		prev = p
		if _lr != null:
			_lr.call("SetMouseState", 0,
				int(round(travel.x * SENSITIVITY)),
				int(round(travel.z * SENSITIVITY)), 0)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := _sv.get_texture().get_image()
		if img != null and not img.is_empty():
			img.save_png("%s/ms_%04d.png" % [OUT, _saved])
			_saved += 1
		elapsed += dt

	print("[scene] saved %d frames" % _saved)
	get_tree().quit(0)
