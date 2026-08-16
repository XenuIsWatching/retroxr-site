## Captures the per-game saves page, for the website's saves/backup page.
##
## Reached in-app from the list icon on a ROM's row; here it is opened directly
## on the spawn view that owns it.
##
##   godot --path RetroXR --resolution 320x240 --position 20,20 \
##       res://Tools/saves_shot.tscn
extends Node

const OUT := "res://probe_out/saves"
const SIZE := Vector2i(2200, 1500)

var _sv: SubViewport = null
var _menu: Control = null


func _ready() -> void:
	get_tree().create_timer(400.0).timeout.connect(func() -> void:
		print("[saves] TIMEOUT")
		get_tree().quit(1))
	_run.call_deferred()


func _settle(n: int = 30) -> void:
	for i in range(n):
		await get_tree().process_frame


func _save(name: String) -> void:
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	var img := _sv.get_texture().get_image()
	if img == null or img.is_empty():
		print("[saves] %s EMPTY" % name)
		return
	img.save_png("%s/%s.png" % [OUT, name])
	print("[saves] %-26s %dx%d" % [name, img.get_width(), img.get_height()])


## First ROM found for a system, so the panel has something real to list.
func _first_rom(sid: String) -> String:
	var root := RomLibrary.default_roms_root().path_join(sid)
	var d := DirAccess.open(root)
	if d == null:
		return ""
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		if not d.current_is_dir():
			return root.path_join(f)
		f = d.get_next()
	return ""


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	_sv = SubViewport.new()
	_sv.size = SIZE
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_sv)

	_menu = load("res://Scenes/UI/spawn_menu.tscn").instantiate()
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sv.add_child(_menu)
	await _settle(150)

	_menu.call("_show_spawn_view")
	await _settle(40)

	var view: Object = _menu.get("_spawn_view")
	if view == null:
		print("[saves] no _spawn_view")
		get_tree().quit(1)
		return

	for sid in ["nes", "playstation", "snes", "game_boy"]:
		var rom := _first_rom(sid)
		if rom.is_empty():
			print("[saves] no rom for %s" % sid)
			continue
		view.call("_show_game_saves_panel", sid, rom, rom.get_file().get_basename())
		await _settle(70)
		await _save("saves_" + sid)
		if view.has_method("_close_game_saves_panel"):
			view.call("_close_game_saves_panel")
			await _settle(10)

	print("[saves] done")
	get_tree().quit(0)
