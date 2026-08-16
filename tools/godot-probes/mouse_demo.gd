## Records a real core being driven by the mouse, for the website's keyboard and
## mouse page.
##
## Boots ScummVM on The Secret of Monkey Island, skips the opening with ESC,
## then walks the pointer around the screen and captures the core's own video
## output frame by frame. Nothing is faked: SetMouseState feeds the same channel
## a MouseReceiver does, and the cursor you see is the game drawing it.
##
##   godot --path RetroXR --resolution 320x240 --position 20,20 \
##       res://Tools/mouse_demo.tscn -- --boot=25 --skip=45 --shoot=14
##
## Frames land in res://probe_out/mouse_demo/. Throwaway.
extends Node

const OUT := "res://probe_out/mouse_demo"
const CORE := "scummvm"
const RETRO_DEVICE_MOUSE := 2
const RETROK_ESCAPE := 27
const RETROK_SPACE := 32

## Seconds: wait for the core to produce a picture, then hammer ESC to get past
## the opening, then record.
var _boot := 25.0
var _skip := 45.0
var _shoot := 14.0

var _lr: Node = null
var _saved := 0


func _ready() -> void:
	get_tree().create_timer(400.0).timeout.connect(func() -> void:
		print("[mouse] TIMEOUT")
		get_tree().quit(1))
	_run.call_deferred()


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


func _pic() -> Image:
	var tex: Texture2D = _lr.call("GetVideoTexture")
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null or img.is_empty():
		return null
	return img


func _wait(sec: float) -> void:
	var t := 0.0
	while t < sec:
		await get_tree().process_frame
		t += get_process_delta_time()


func _tap(keycode: int) -> void:
	_lr.call("SetKeyState", 0, keycode, true, 0)
	await _wait(0.08)
	_lr.call("SetKeyState", 0, keycode, false, 0)


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
		print("[mouse] no Monkey Island under roms/scummvm")
		get_tree().quit(1)
		return
	print("[mouse] rom: %s" % rom)

	_lr = ClassDB.instantiate("Libretro")
	if _lr == null:
		print("[mouse] Libretro class unavailable")
		get_tree().quit(1)
		return
	add_child(_lr)

	var root := CoreDownloadManager.default_core_root()
	print("[mouse] core root: %s" % root)
	_lr.call("SetInputEnabled", true)
	_lr.call("SetControllerPortDevice", 0, RETRO_DEVICE_MOUSE)
	_lr.call("SetAudioPlaying", false)
	_lr.call("StartContent", root, CORE, rom)

	# Wait for a picture rather than a fixed sleep — cores differ wildly in how
	# long they take to produce their first frame.
	var waited := 0.0
	while waited < _boot:
		await _wait(0.5)
		waited += 0.5
		var img := _pic()
		if img != null:
			print("[mouse] first frame after %.1fs, %dx%d"
				% [waited, img.get_width(), img.get_height()])
			break

	# Get past the logos and the opening. ESC skips ScummVM cutscenes; space
	# clears dialogue that ESC will not.
	# ESC only. SPACE is PAUSE in SCUMM, not "continue" — sending it parked the
	# game on "Game Paused. Press SPACE to Continue." for the whole recording.
	var t := 0.0
	while t < _skip:
		await _tap(RETROK_ESCAPE)
		await _wait(2.0)
		t += 2.1
	print("[mouse] skip phase done (%.0fs), frames=%s"
		% [_skip, str(_lr.call("GetFrameCount"))])

	for i in range(30):
		_lr.call("SetMouseState", 0, 3, 2, 0)
		await get_tree().process_frame

	# Walk the pointer on a slow ellipse. Deltas are relative and per-frame, so
	# this is a velocity, not a position.
	var elapsed := 0.0
	var phase := 0.0
	while elapsed < _shoot:
		var dt := get_process_delta_time()
		phase += dt * 1.5
		var dx := int(round(cos(phase) * 7.0))
		var dy := int(round(sin(phase * 0.8) * 4.0))
		var buttons := 1 if fmod(phase, 6.283) < 0.25 else 0
		_lr.call("SetMouseState", 0, dx, dy, buttons)
		await get_tree().process_frame
		var img := _pic()
		if img != null:
			img.save_png("%s/md_%04d.png" % [OUT, _saved])
			_saved += 1
		elapsed += dt

	print("[mouse] saved %d frames" % _saved)
	_lr.call("StopContent")
	await _wait(1.0)
	get_tree().quit(0)
