## Renders each spawn-menu view to a PNG for the website's guide pages.
##
## Windowed, never --headless: a SubViewport on UPDATE_ALWAYS has no GPU to
## service it under the dummy renderer and the run hangs.
##
##   "$godot" --path RetroXR --resolution 320x240 --position 20,20 \
##       res://Tools/menu_shots.tscn
##
## PNGs land in res://probe_out/menu/ (gitignored). Throwaway — delete the
## .gd/.tscn/.uid when the shots are captured.
extends Node

const OUT := "res://probe_out/menu"
const SIZE := Vector2i(2200, 1500)

## Top-level nav views, by the method that shows each one.
const VIEWS: Array = [
	["spawn", "_show_spawn_view"],
	["cores", "_show_cores_view"],
	["controls", "_show_controls_view"],
	["options", "_show_options_view"],
	["graphics", "_show_graphics_view"],
	["scene", "_show_scene_view"],
	["net", "_show_net_view"],
	["about", "_show_about_view"],
]

var _sv: SubViewport = null
var _menu: Control = null
var _saved: int = 0


func _ready() -> void:
	get_tree().create_timer(300.0).timeout.connect(func() -> void:
		push_error("[shots] TIMEOUT")
		get_tree().quit(1))
	_run()


func _settle(frames: int = 24) -> void:
	for i in range(frames):
		await get_tree().process_frame


func _save(name: String) -> void:
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	var img := _sv.get_texture().get_image()
	var path := "%s/%s.png" % [OUT, name]
	var err := img.save_png(path)
	if err != OK:
		print("[shots] FAILED %s err=%d" % [name, err])
		return
	_saved += 1
	print("[shots] %-28s %dx%d" % [name, img.get_width(), img.get_height()])


## The TabContainer inside the SPAWN view, found by type so the probe does not
## depend on two layers of private member names.
func _find_tabs(n: Node) -> TabContainer:
	if n is TabContainer:
		return n as TabContainer
	for c in n.get_children():
		var found := _find_tabs(c)
		if found != null:
			return found
	return null


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	_sv = SubViewport.new()
	_sv.size = SIZE
	_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sv.transparent_bg = false
	add_child(_sv)

	_menu = load("res://Scenes/UI/spawn_menu.tscn").instantiate()
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sv.add_child(_menu)

	# The platform fetch has to land or the grids photograph empty.
	await _settle(150)

	for entry in VIEWS:
		var slug: String = entry[0]
		var fn: String = entry[1]
		if not _menu.has_method(fn):
			print("[shots] no method %s" % fn)
			continue
		_menu.call(fn)
		await _settle(40)
		await _save(slug)

		if slug == "spawn":
			await _shoot_spawn_tabs()

	print("[shots] done, %d saved to %s" % [_saved, OUT])
	get_tree().quit(0)


func _shoot_spawn_tabs() -> void:
	var tabs := _find_tabs(_menu)
	if tabs == null:
		print("[shots] no TabContainer in the spawn view")
		return
	print("[shots] spawn tabs: %d" % tabs.get_tab_count())
	for i in range(tabs.get_tab_count()):
		var title: String = tabs.get_tab_title(i)
		tabs.current_tab = i
		await _settle(50)
		await _save("spawn_" + title.to_lower().replace(" ", "_"))
