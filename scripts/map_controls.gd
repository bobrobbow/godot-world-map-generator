extends Node2D

onready var left_click_captured = false
onready var right_click_captured = false
var highlighted_coord = Vector2()
onready var tilemap_cell_size = Vector2( 32, 32 )
onready var color = Color(0.4, 0.9, 0.4)
onready var right_gui = get_parent().get_parent().get_parent().get_parent().get_node("right_gui")

func _ready():
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_select"):
		get_parent().get_node("heat_map").hide()
		get_parent()._generate_data(true)
		get_parent().get_node("map").set_modulate(Color(1.0,1.0,1.0,1.0))
		get_parent().get_node("map").set_self_modulate(Color(1.0,1.0,1.0,1.0))
	if event.is_action_pressed(("ui_focus_next")):
		get_parent()._generate_heat_map()
	if event.is_action_pressed("rightclick"):
		pass
	elif event.is_action_released("rightclick"):
		right_click_captured = false
	if event is InputEventMouseMotion:
		var mousepos = get_global_mouse_position()
		var coordpos = get_parent().map_tilemap.world_to_map( mousepos )
		#get_node("/root/local_map_scene/coord").text = str(coordpos)
		highlighted_coord = coordpos
		right_gui.get_node("cursor_coord_text").set_text("Coord of cursor is : " + str(coordpos.x) + " " + str(coordpos.y))
		var _height = 0
		if get_parent().height_map.has(coordpos):
			_height = get_parent().height_map[coordpos]
		var terrain_name = ""
		var temperature_str = ""
		if get_parent().get_node("map").get_cellv(coordpos) != -1:
			terrain_name = get_parent().combined_map_data[coordpos]["name"]
			temperature_str = str(get_parent().temperature_map[coordpos])
		right_gui.get_node("cursor_tile_text").set_text("terrain at cursor is : " + terrain_name )
		right_gui.get_node("cursor_tile_text2").set_text("temperature :" + temperature_str)
		
func _process(_delta):
	right_gui.get_node("fps_text").set_text( str(Engine.get_frames_per_second()))
	update()

func _draw():
	var sizex = tilemap_cell_size.x
	var sizey = tilemap_cell_size.y
	var x = highlighted_coord.x * sizex
	var y = highlighted_coord.y * sizey
	# first horizontal line
	draw_line( Vector2( x, y ), Vector2( x + sizex, y ), color )
	# second horizontal line
	draw_line( Vector2( x, y + sizey ), Vector2( x + sizex, y + sizey ) , color )
	# first vertical line
	draw_line( Vector2( x, y ), Vector2( x, y + sizey ), color )
	# second horizontal line
	draw_line( Vector2( x + sizex, y ), Vector2( x + sizex, y + sizey ), color )

