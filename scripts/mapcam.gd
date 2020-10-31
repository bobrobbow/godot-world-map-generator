extends Camera2D


var zoom_step = 1.1
var min_zoom = 0.2
var max_zoom = 20.0
var pan_speed = 800
var mouse_captured = false
var limit_rect = Rect2(Vector2(0,0),Vector2(50000,50000))
var camera_follow = false
onready var right_gui = get_parent().get_parent().get_parent().get_parent().get_node("right_gui")

func _update_moused_tile():
	var mousepos = get_global_mouse_position()
	var coordpos = get_parent().get_node("map").world_to_map( mousepos )
	get_parent().get_node("map_controls").highlighted_coord = coordpos

func _physics_process(delta):
	right_gui.get_node("camera_info_text").set_text("camera pos = " + str(int(position.x)) + " " + str(int(position.y)) + " zoom = " + str(stepify(zoom.x,0.1)) + " " + str(stepify(zoom.y,0.1)))
	if Input.is_action_pressed("ui_left"):
		camera_follow = false
		position.x = position.x - pan_speed * delta
		_update_moused_tile()
	if Input.is_action_pressed("ui_right"):
		position.x = position.x + pan_speed * delta
		camera_follow = false
		_update_moused_tile()
	if Input.is_action_pressed("ui_down"):
		position.y = position.y + pan_speed * delta
		camera_follow = false
		_update_moused_tile()
	if Input.is_action_pressed("ui_up"):
		position.y = position.y - pan_speed * delta
		camera_follow = false
		_update_moused_tile()
	_snap_to_limits()

func _input(event):
	if event.is_action_pressed("view_pan_mouse"):
		mouse_captured = true
		camera_follow = false
	elif event.is_action_released("view_pan_mouse"):
		mouse_captured = false
	if mouse_captured && event is InputEventMouseMotion:
		position -= event.relative * zoom #like we're grabbing the map
	if event is InputEventMouse:
		if event.is_pressed() and not event.is_echo():
			var mouse_position = event.position
			if event.button_index == BUTTON_WHEEL_DOWN:
				if zoom < Vector2( max_zoom, max_zoom ):
					zoom_at_point(zoom_step,mouse_position)
					_snap_zoom_limits()
			elif event.button_index == BUTTON_WHEEL_UP:
				if zoom > Vector2( min_zoom, min_zoom ):
					zoom_at_point(1/zoom_step,mouse_position)
					_snap_zoom_limits()
	if event.is_action_pressed("zoom_in"):
		zoom /= zoom_step
		_snap_zoom_limits()
	if event.is_action_pressed("zoom_out"):
		zoom *= zoom_step
		_snap_zoom_limits()

func zoom_at_point(zoom_change, point):
	var c0 = global_position # camera position
	var v0 = get_viewport().size # vieport size
	var c1 # next camera position
	var z0 = zoom # current zoom value
	var z1 = z0 * zoom_change # next zoom value

	c1 = c0 + (-0.5*v0 + point)*(z0 - z1)
	zoom = z1
	global_position = c1

# force position to be inside limit_rect
func _snap_to_limits():
	position.x = clamp(position.x, limit_rect.position.x, limit_rect.end.x)
	position.y = clamp(position.y, limit_rect.position.y, limit_rect.end.y)

func _snap_zoom_limits():
	zoom.x = clamp(zoom.x, min_zoom, max_zoom)
	zoom.y = clamp(zoom.y, min_zoom, max_zoom)
	var mousepos = get_global_mouse_position()
	var coordpos = get_parent().get_node("map").world_to_map( mousepos )
	get_parent().get_node("map_controls").highlighted_coord = coordpos
