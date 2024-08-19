extends CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$leveloverlay.play("default")
	pass


func _on_texture_button_pressed():
	var menu = load("res://scenes/menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	hide()


func _on_level_1_pressed():
	var level1 = load("res://scenes/level1.tscn").instantiate()
	get_tree().root.add_child(level1)
	hide()


func _on_level_2_pressed():
	var level2 = load("res://scenes/level2.tscn").instantiate()
	get_tree().root.add_child(level2)
	hide()


func _on_level_3_pressed():
	var level3 = load("res://scenes/level3.tscn").instantiate()
	get_tree().root.add_child(level3)
	queue_free()
