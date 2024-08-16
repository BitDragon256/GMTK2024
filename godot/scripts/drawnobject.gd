extends RigidBody2D


var points = []
var done_drawing = false

func _ready() -> void:
	freeze = true
	pass


func _process(_delta: float) -> void:
	if Input.is_action_pressed("draw") && !done_drawing:
		var point = get_viewport().get_mouse_position()
		if points != []:
			var last = points.back()
			var seg = Sprite2D.new()
			seg.texture = load("res://assets//white capsule.png")
			seg.position = (point + points.back()) / 2.0
			seg.scale.x = ((point - last).length() + 5.0) / 64.0
			seg.scale.y = 10.0 / 64.0
			seg.rotate(atan2((point - last).y, (point - last).x))
			add_child(seg)
		points.push_back(point)

	if Input.is_action_just_released("draw"):
		if !done_drawing:
			var last = points.front()
			for p in points:
				var seg = CollisionShape2D.new()
				seg.shape = CapsuleShape2D.new()
				seg.position = (p + last) / 2
				seg.rotate(atan2((p - last).y, (p - last).x) + PI / 2.0)
				seg.shape.height = (p - last).length() + 5
				seg.shape.radius = 10
				add_child(seg)
				last = p

			freeze = false

		done_drawing = true
