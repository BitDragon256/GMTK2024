extends CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Control/startButton/AnimatedSprite2D.play("default")
	$Control/quitButton/AnimatedSprite2D.play("default")
	pass

func _on_start_button_pressed():
	var nextScene = load("res://scenes/levelmenu.tscn").instantiate()
	get_tree().root.add_child(nextScene)
	queue_free()

func _on_quit_button_pressed():
	get_tree().quit()
