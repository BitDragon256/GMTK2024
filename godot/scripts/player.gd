extends CharacterBody2D


const DRAWING_WIDTH = 4


const SPEED = 400.0
const JUMP_ACCELERATION = -50.0
const JUMP_START_ACCELERATION = -400.0
const JUMP_ACCELERATION_DECLINE = 50

const MAX_JUMP_TIME = 0.2
var released_jump_btn = false
var pressed_jump_btn = false
var jump_timer = Timer.new()

const COYOTE_TIME = 0.4
var coyote_timer = Timer.new()

const CAMERA_PREWALK = 60
const CAMERA_PREWALK_SPEED = 1.0 / 18.0
func camera_smoothing(a, b):
	return a + (b - a) * CAMERA_PREWALK_SPEED

@onready var _camera = $Camera2D
@onready var _sprite = $AnimatedSprite2D

func _init():
	jump_timer.wait_time = MAX_JUMP_TIME
	jump_timer.one_shot = true
	add_child(jump_timer)

	coyote_timer.wait_time = COYOTE_TIME
	coyote_timer.one_shot = true
	add_child(coyote_timer)
	pass

func drawn_is_grounded() -> bool:
	if get_slide_collision_count() > 0:
		var last_collision = get_slide_collision(0)
		if (abs(last_collision.get_position().x - position.x) > $CollisionShape2D.shape.radius || abs(last_collision.get_position().y - position.y) > $CollisionShape2D.shape.height) && last_collision.get_angle() < 0.5:
			return true
	return false

func grounded() -> bool:
	if drawn_is_grounded():
		return false
	return is_on_floor()

var jumped = false
var erased = false
var burned = false

func handle_movement(delta: float):
	if erased or burned:
		return
	if grounded():
		coyote_timer.start()
		pressed_jump_btn = false
	else:
		velocity += get_gravity() * delta

	if grounded() || !coyote_timer.is_stopped():
		released_jump_btn = false

	if Input.is_action_pressed("jump"):
		if (grounded() || !coyote_timer.is_stopped()) && !pressed_jump_btn:
			jump_timer.start()
			pressed_jump_btn = true
			velocity.y += JUMP_START_ACCELERATION
			jumped = true
			if !grounded():
				velocity.y = JUMP_START_ACCELERATION
		if not jump_timer.is_stopped() && not released_jump_btn:
			velocity.y += JUMP_ACCELERATION + (1.0 - jump_timer.time_left / MAX_JUMP_TIME) * JUMP_ACCELERATION_DECLINE
	else:
		released_jump_btn = true

	var direction := Input.get_axis("move_left", "move_right")
	if direction && !drawn_is_grounded():
		velocity.x = direction * SPEED

		_sprite.flip_h = direction < 0
		_sprite.offset.x = min(sign(direction), 0) * 180
		_sprite.offset.y = 80
		if grounded():
			_sprite.play("run")
		else:
			if jumped:
				jumped = false
				_sprite.play("jump_side")
			elif !_sprite.is_playing():
				_sprite.play("falling_side")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

		_sprite.offset.y = 0
		if grounded():
			_sprite.offset.y = 0
			_sprite.play("idle")
		else:
			if jumped:
				jumped = false
				_sprite.play("jump_straight")
			elif !_sprite.is_playing():
				_sprite.play("falling")

	if !drawn_is_grounded():
		_camera.offset.x = camera_smoothing(_camera.offset.x, CAMERA_PREWALK * direction)

	move_and_slide()

var done_drawing = false
var cut_drawing = true
var image_segments = []
@onready var draw_image_root = $DrawObject/ImageRoot
@onready var draw_object = $DrawObject

var segment_colliders = []

var last_mouse_pos: Vector2
var use_horizontal = false
var use_vertical = false

var released = false
var start_animation = true


func _ready() -> void:
	_sprite.play("start")
	last_mouse_pos = get_global_mouse_position()

func handle_drawing():
	var mouse_pos = get_global_mouse_position()
	if Input.is_action_pressed("draw") && !done_drawing:
		var delta = last_mouse_pos - mouse_pos
		if $DrawObject/horizontal.call("mouse_is_over") && !use_vertical:
			use_horizontal = true
		if $DrawObject/vertical.call("mouse_is_over") && !use_horizontal:
			use_vertical = true
		if $DrawObject/origin.call("mouse_is_over") && !use_vertical && !use_horizontal:
			use_horizontal = true
			use_vertical = true

		if use_horizontal:
			draw_object.position.x -= delta.x
			for seg in segment_colliders:
				for s in seg:
					s[4].x += delta.x
			for seg in image_segments:
				seg.position.x += delta.x
		if use_vertical:
			draw_object.position.y -= delta.y
			for seg in segment_colliders:
				for s in seg:
					s[4].y += delta.y
			for seg in image_segments:
				seg.position.y += delta.y

		var block_draw = false
		if use_vertical || use_horizontal || !get_node("../drawingSection").call("mouse_is_over"):
			block_draw = true
		
		if !block_draw:
			var point = transformViewportToLocal(get_global_mouse_position())
			if cut_drawing:
				segment_colliders.push_back([])
				image_segments.push_back(Node2D.new())
				draw_image_root.add_child(image_segments.back())

			else:
				# add segments
				var last = transformViewportToLocal(last_mouse_pos)
				var pointSquareSprite = Sprite2D.new()
				pointSquareSprite.texture = load("res://assets//black square.png")
				pointSquareSprite.position = (point + last) / 2.0
				pointSquareSprite.scale.x = max(((point - last).length() + DRAWING_WIDTH / 2.0), DRAWING_WIDTH) / 64.0
				pointSquareSprite.scale.y = DRAWING_WIDTH / 64.0
				pointSquareSprite.rotate(atan2((point - last).y, (point - last).x))
				image_segments.back().add_child(pointSquareSprite)

				# add connector pieces
				var pointCircleSprite = Sprite2D.new()
				pointCircleSprite.texture = load("res://assets/black circle.png")
				pointCircleSprite.scale.x = DRAWING_WIDTH / 64.0
				pointCircleSprite.scale.y = DRAWING_WIDTH / 64.0
				pointCircleSprite.position = point
				image_segments.back().add_child(pointCircleSprite)

				# add collider
				var collider = CollisionPolygon2D.new()
				var width = DRAWING_WIDTH
				var height = (point - last).length() + DRAWING_WIDTH / 2.0
				var rot = atan2((point - last).y, (point - last).x) + PI / 2.0
				var pos = (point + last) / 2
				var transformMat = Transform2D.IDENTITY.rotated(rot).translated(pos)
				var colliderVertices = PackedVector2Array()
				colliderVertices.push_back(transformMat * Vector2(width / 2.0, -height / 2.0))
				colliderVertices.push_back(transformMat * Vector2(width / 2.0, height / 2.0))
				colliderVertices.push_back(transformMat * Vector2(-width / 2.0, height / 2.0))
				colliderVertices.push_back(transformMat * Vector2(-width / 2.0, -height / 2.0))
				collider.polygon = colliderVertices
				add_child(collider)

				segment_colliders.back().push_back([collider, width, height, rot, pos, draw_object.position])

			cut_drawing = false 

	if Input.is_action_just_released("draw"):
		cut_drawing = true
		use_vertical = false
		use_horizontal = false

	last_mouse_pos = mouse_pos

func draw_button_pressed() -> void:
	done_drawing = true
	get_node("../drawingSection").hide()
	get_node("../HUD/Button").hide()
	get_node("../HUD/Button2").show()

	$DrawObject/horizontal/Sprite2D.texture = load("res://assets/controlRig/scalingBarSideways.png")
	$DrawObject/vertical/Sprite2D.texture = load("res://assets/controlRig/scalingBarUpways.png")


func release_button_pressed() -> void:
	released = !released
	if !released: # if the drawing is anchored on the player
		# draw_object.freeze = true
		for group in segment_colliders:
			for seg in group:
				seg[5] = draw_object.position
				draw_object.remove_child(seg[0])
				add_child(seg[0])
	else:
		# draw_object.freeze = false
		for group in segment_colliders:
			for seg in group:
				seg[5] = Vector2.ZERO
				remove_child(seg[0])
				draw_object.add_child(seg[0])


@onready var last_pos = position
func move_drawn_object():
	if released:
		var delta = position - last_pos
		draw_object.position -= delta
	last_pos = position

const SCALING_FACTOR = 100
var draw_object_scale = Vector2(1,1)

func update_collider_scaling():
	for group in segment_colliders:
		for seg in group:
			var collider = seg[0]
			var width = seg[1]
			var height = seg[2]
			var rot = seg[3]
			var pos = seg[4]
			var origin = seg[5]

			var tfr = Transform2D.IDENTITY.rotated(rot).translated(pos).scaled(draw_object_scale).translated(origin)

			collider.polygon[0] = tfr * Vector2(width / 2.0, -height / 2.0)
			collider.polygon[1] = tfr * Vector2(width / 2.0, height / 2.0)
			collider.polygon[2] = tfr * Vector2(-width / 2.0, height / 2.0)
			collider.polygon[3] = tfr * Vector2(-width / 2.0, -height / 2.0)

func handle_scaling():
	if Input.is_action_pressed("draw"):
		var mouse_pos = get_global_mouse_position()
		var delta = last_mouse_pos - mouse_pos
		if $DrawObject/horizontal.call("mouse_is_over") && !use_vertical:
			use_horizontal = true
		if $DrawObject/vertical.call("mouse_is_over") && !use_horizontal:
			use_vertical = true
		if $DrawObject/origin.call("mouse_is_over") && !use_vertical && !use_horizontal:
			use_horizontal = true
			use_vertical = true

		if use_horizontal:
			draw_object_scale.x -= delta.x / SCALING_FACTOR
		if use_vertical:
			draw_object_scale.y += delta.y / SCALING_FACTOR

		draw_image_root.scale = draw_object_scale		
# func handleEndOfLevel():
	

func transformViewportToLocal(viewportPosition: Vector2):
	return viewportPosition - position - draw_object.position

func _physics_process(delta: float) -> void:
	if start_animation && _sprite.is_playing():
		return
	start_animation = false

	if done_drawing:
		handle_movement(delta)
		handle_scaling()
	else:
		_sprite.play("idle")
		
	if Input.is_action_just_pressed("release"):
		release_button_pressed()

	handle_drawing()
	move_drawn_object()
	update_collider_scaling()
	
func endOfLevel():
	get_node("../drawingSection").hide()
	get_node("../HUD/Button").hide()
	get_node("../HUD/Button2").hide()
	get_node("../HUD/Button3").hide()
	queue_free()
	
func reset():
	var scene = load("res://scenes/level1.tscn").instantiate()
	get_tree().root.add_child(scene)
	get_node("../HUD/Button2").hide()
	queue_free()

func _on_reset_button_pressed():
	reset()

func _on_laser_area_entered(area):
	if area != $bodyCollisionArea:
		return
	burned = true
	$AnimatedSprite2D.play("erase")
	

func _on_end_of_level_area_entered(area):
	print("finished")
	if area != $bodyCollisionArea:
		return
	erased = true
	$AnimatedSprite2D.play("erase")

# reset everything
func _on_animated_sprite_2d_animation_finished():
	if erased:
		var levelmenu = load("res://scenes/levelmenu.tscn").instantiate()
		get_tree().root.add_child(levelmenu)
		endOfLevel()
	if burned:
		reset() 
	
