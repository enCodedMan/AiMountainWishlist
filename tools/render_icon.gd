## Renders icon.png: xvfb-run godot --path . -s tools/render_icon.gd
extends SceneTree
var n := 0
var vp: SubViewport
func _init():
	vp = SubViewport.new()
	vp.size = Vector2i(512, 512)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var c := Node2D.new()
	c.set_script(load("res://tools/icon_art.gd"))
	vp.add_child(c)
func _process(_d):
	n += 1
	if n == 6:
		vp.get_texture().get_image().save_png("res://icon.png")
		quit()
