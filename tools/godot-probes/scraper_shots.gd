## Captures the two screens the website's "box art and manuals" page annotates:
## the Scraper options tab, and a cartridge's detail page where a scrape starts.
##
## Windowed, never --headless.
##
##   godot --path RetroXR --resolution 320x240 --position 20,20 \
##       res://Tools/scraper_shots.tscn
##
## PNGs land in res://probe_out/scraper/. Throwaway.
extends Node

const OUT := "res://probe_out/scraper"
const SIZE := Vector2i(2200, 1500)

var _sv: SubViewport = null
var _menu: Control = null


func _ready() -> void:
	get_tree().create_timer(400.0).timeout.connect(func() -> void:
		print("[scrape] TIMEOUT")
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
		print("[scrape] %s EMPTY" % name)
		return
	img.save_png("%s/%s.png" % [OUT, name])
	print("[scrape] %-22s %dx%d" % [name, img.get_width(), img.get_height()])


## Every TabContainer in the tree, so the one actually on screen can be picked —
## the spawn view's stays in the tree while the options view is showing.
func _all_tabs(n: Node, acc: Array) -> Array:
	if n is TabContainer and (n as TabContainer).is_visible_in_tree():
		acc.append(n)
	for c in n.get_children():
		_all_tabs(c, acc)
	return acc


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

	# ── Options sub-tabs ─────────────────────────────────────────────────────
	_menu.call("_show_options_view")
	await _settle(40)

	var tabs: Array = _all_tabs(_menu, [])
	if tabs.is_empty():
		print("[scrape] no visible TabContainer under options")
	else:
		var t: TabContainer = tabs[0]
		print("[scrape] options tabs: %d" % t.get_tab_count())
		for i in range(t.get_tab_count()):
			var title: String = t.get_tab_title(i)
			t.current_tab = i
			await _settle(40)
			await _save("options_" + title.to_lower().replace(" ", "_"))

	# ── A cartridge's detail page, where a scrape is started ─────────────────
	_menu.call("_show_spawn_view")
	await _settle(50)

	# The browser belongs to the spawn view, not the menu.
	var spawn_view: Object = _menu.get("_spawn_view")
	var browser: Object = spawn_view.get("_cartridges_browser") if spawn_view != null else null
	if browser == null:
		print("[scrape] no _cartridges_browser (spawn_view=%s)" % str(spawn_view))
		get_tree().quit(0)
		return

	# The browser only draws when its own tab is the one showing.
	var stabs: Array = _all_tabs(_menu, [])
	if not stabs.is_empty():
		var st: TabContainer = stabs[0]
		for i in range(st.get_tab_count()):
			if st.get_tab_title(i) == "Cartridges":
				st.current_tab = i
				break
		await _settle(60)

	for sid in ["nes", "snes", "nintendo_64", "playstation", "game_boy"]:
		browser.call("open_system", sid)
		await _settle(60)
		await _save("cartridges_detail_" + sid)

	print("[scrape] done")
	get_tree().quit(0)
