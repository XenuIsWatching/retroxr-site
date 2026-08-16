## The Wii Remote's four player LEDs, one still per slot, for the website.
##
## The LED materials are rebuilt by the remote every frame from its pairing
## state, so this drives the meshes directly rather than trying to fake a
## pairing: same colours, same emission, from the remote's own constants.
##
##   godot --path RetroXR --resolution 320x240 --position 20,20 \
##       res://Tools/wii_leds_shot.tscn
extends Node

const OUT := "res://probe_out/wii_leds"
const SIZE := Vector2i(1400, 700)
const BACKDROP := Color(0.043, 0.059, 0.11)
const WIIMOTE := "res://Scenes/Objects/controllers/wii/wiimote.tscn"

const LED_OFF := Color(0.06, 0.07, 0.12)
const LED_ON := Color(0.25, 0.6, 1.0)

var _sv: SubViewport = null
var _mats: Array = []


func _ready() -> void:
	get_tree().create_timer(240.0).timeout.connect(func() -> void:
		print("[leds] TIMEOUT")
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


func _set_slot(slot: int) -> void:
	for i in range(_mats.size()):
		var lit := (slot < 0) or (i == slot)
		var m: StandardMaterial3D = _mats[i]
		m.albedo_color = LED_ON if lit else LED_OFF
		m.emission_energy_multiplier = 1.6 if lit else 0.0


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	_sv = SubViewport.new()
	_sv.size = SIZE
	_sv.own_world_3d = true
	_sv.msaa_3d = Viewport.MSAA_4X
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sv)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = BACKDROP
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.60, 0.72)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.72
	# Bloom, so a lit LED reads as lit rather than as a slightly bluer square.
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.25
	var we := WorldEnvironment.new()
	we.environment = env
	_sv.add_child(we)

	var key := DirectionalLight3D.new()
	key.light_energy = 0.8
	key.rotation_degrees = Vector3(-55.0, 25.0, 0.0)
	_sv.add_child(key)

	var remote: Node = load(WIIMOTE).instantiate()
	_sv.add_child(remote)
	_freeze_all(remote)
	for i in range(25):
		await get_tree().process_frame
	_freeze_all(remote)

	var leds := _find(remote, "PlayerLEDs") as Node3D
	if leds == null:
		print("[leds] no PlayerLEDs")
		get_tree().quit(1)
		return

	var centre := Vector3.ZERO
	var n := 0
	for i in range(1, 5):
		var mi := _find(leds, "LED%d" % i) as MeshInstance3D
		if mi == null:
			continue
		var m := StandardMaterial3D.new()
		m.albedo_color = LED_OFF
		m.emission_enabled = true
		m.emission = LED_ON
		m.emission_energy_multiplier = 0.0
		mi.set_surface_override_material(0, m)
		_mats.append(m)
		centre += mi.global_position
		n += 1
	if n == 0:
		print("[leds] no LED meshes")
		get_tree().quit(1)
		return
	centre /= float(n)
	print("[leds] %d LEDs, centre %v" % [n, centre])

	var cam := Camera3D.new()
	cam.fov = 26.0
	cam.near = 0.001
	_sv.add_child(cam)
	# Straight down onto the LED strip, which sits on the remote's top face.
	cam.position = centre + Vector3(0.0, 0.105, 0.012)
	cam.look_at(centre)
	cam.current = true

	for i in range(10):
		await get_tree().process_frame

	for slot in [-1, 0, 1, 2, 3]:
		_set_slot(slot)
		for i in range(4):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		await get_tree().process_frame
		var img := _sv.get_texture().get_image()
		var name := "unpaired" if slot < 0 else "p%d" % (slot + 1)
		img.save_png("%s/leds_%s.png" % [OUT, name])
		print("[leds] %s" % name)

	print("[leds] done")
	get_tree().quit(0)
