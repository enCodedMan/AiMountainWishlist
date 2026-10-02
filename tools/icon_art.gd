extends Node2D
## Draws the app icon (render with tools/ scripts; output is icon.png).

func _draw() -> void:
	draw_rect(Rect2(0, 0, 512, 512), Color("13121c"))
	var cell := 112.0
	var o := Vector2(32, 32)
	for y in 4:
		for x in 4:
			draw_rect(Rect2(o + Vector2(x, y) * cell, Vector2(cell, cell)), Color("8a5a3c") if (x + y) % 2 == 1 else Color("e9d8b4"))
	var c := o + Vector2(1.5, 2.5) * cell
	draw_circle(c, 46, Color("f4f1ea").darkened(0.35))
	draw_circle(c, 38, Color("f4f1ea"))
	draw_circle(c, 18, Color("f5c542"))
	for p in [Vector2(2.5, 1.5), Vector2(0.5, 1.5)]:
		var q: Vector2 = o + p * cell
		draw_circle(q, 46, Color("c0392b").darkened(0.35))
		draw_circle(q, 38, Color("c0392b"))
	# The jump arc
	draw_arc(o + Vector2(2.5, 1.5) * cell, 158, PI * 0.75 + 0.35, PI * 1.75 - 0.3, 32, Color("f5c542"), 12)
	draw_circle(o + Vector2(3.5, 0.5) * cell, 14, Color("f5c542"))
