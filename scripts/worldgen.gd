extends Node2D


var deep_water = 0
var shallow_water = 1
var mountain = 10
var ice = 2
var forest = 3
var jungle = 4
var grassland = 5
var desert = 7
var swamp = 8
var octaves = 8
var period = 1.0
var persistence = 0.8
var lacunarity = 2.0
var world_size = Vector2(300,300)
var height_map = {}
var height_noise
var moisture_noise
var temperature_noise
var rng
var water_threshold = 0.67
var shallow_water_threshold = 0.77
var land_threshold = 0.9
var mountain_threshold = 1.4
var exponent = 4.5
var moisture_map = {}
var desert_threshold = 0.4
var grassland_threshold = 0.5
var forest_threshold = 0.95
var jungle_threshold = 1.47
var temp0 = Color(78,19,107) #-81C
var temp1 = Color(124,31,171) #-63C
var temp2 = Color(19,43,107) #-49C
var temp3 = Color(33,71,173) #-33C
var temp4 = Color(111,144,232) #-17C
var temp5 = Color(170,217,126) #0C
var temp6 = Color(224,194,40) #15C
var temp7 = Color(209,85,19) #30C
var temp8 = Color(255,0,0) #46C
onready var map_tilemap = $map
onready var map_cam = $map_cam
var combined_map_data = {}
var temperature_map = {}
var temp_variation_noise = 80
var temp_at_equator = 55
var temp_at_pole = -55
var heat_map = false
var snow_chance_reduction = 500

# Called when the node enters the scene tree for the first time.
func _ready():
	$heat_map.hide()
	map_cam.position = Vector2((world_size.x / 2) * 32, (world_size.y / 2) * 32)
	$map/border.rect_size = Vector2((world_size.x + 3) * 32,(world_size.y +3) * 32)
	map_tilemap.tile_set.tile_set_name( 0, "deep_water" )
	map_tilemap.tile_set.tile_set_name( 1, "shallow_water" )
	map_tilemap.tile_set.tile_set_name( 10, "mountain" )
	map_tilemap.tile_set.tile_set_name( 2, "ice" )
	map_tilemap.tile_set.tile_set_name( 3, "forest" )
	map_tilemap.tile_set.tile_set_name( 4, "jungle" )
	map_tilemap.tile_set.tile_set_name( 5, "grassland" )
	map_tilemap.tile_set.tile_set_name( 7, "desert" )
	map_tilemap.tile_set.tile_set_name( 8, "swamp" )
	height_noise = OpenSimplexNoise.new()
	moisture_noise = OpenSimplexNoise.new()
	temperature_noise = OpenSimplexNoise.new()
	rng = RandomNumberGenerator.new()
	rng.randomize()
	height_noise.seed = rng.randi() % 999999
	height_noise.octaves = octaves
	height_noise.period = period
	height_noise.persistence = persistence
	height_noise.lacunarity = lacunarity
	moisture_noise.seed = rng.randi() % 999999
	moisture_noise.octaves = octaves
	moisture_noise.period = period
	moisture_noise.persistence = persistence
	moisture_noise.lacunarity = lacunarity
	temperature_noise.seed = rng.randi() % 999999
	temperature_noise.octaves = octaves
	temperature_noise.period = period
	temperature_noise.persistence = persistence
	temperature_noise.lacunarity = lacunarity
	_generate_data(true)

func _generate_data(random):
	if random:
		height_noise.seed = rng.randi() % 999999
		moisture_noise.seed = rng.randi() % 999999
		temperature_noise.seed = rng.randi() % 999999
	for x in range(0,world_size.x + 1):
		for y in range(0,world_size.y + 1):
			var nx = x/world_size.x - 0.5
			var ny = y/world_size.y - 0.5
			#elevation
			var first_height_freq = 1 * _adjusted_noise_range(height_noise.get_noise_2d(1 * nx, 1 * ny))
			var second_height_freq = 0.5 * _adjusted_noise_range(height_noise.get_noise_2d(2 * nx, 2 * ny))
			var third_height_freq = 0.25 * _adjusted_noise_range(height_noise.get_noise_2d(4 * nx, 4 * ny))
			var e = first_height_freq + second_height_freq + third_height_freq
			var data_entry = {}
			var elevation = pow(e,exponent)
			data_entry["elevation"] = elevation
			height_map[Vector2(x,y)] = elevation
			#moisture
			var first_moisture_freq = 1 * _adjusted_noise_range(moisture_noise.get_noise_2d(1 * nx, 1 * ny))
			var second_moisture_freq = 0.5 * _adjusted_noise_range(moisture_noise.get_noise_2d(2 * nx, 2 * ny))
			var third_moisture_freq = 0.25 * _adjusted_noise_range(moisture_noise.get_noise_2d(4 * nx, 4 * ny))
			var m = first_moisture_freq + second_moisture_freq + third_moisture_freq
			var moisture = pow(m,exponent)
			data_entry["moisture"] = moisture
			moisture_map[Vector2(x,y)] = moisture
			#latitude temperature
			var map_shrink_from_base = world_size.x / 400
			var adjusted_temp_noise_variation = temp_variation_noise * map_shrink_from_base
			var first_temp_freq = 1 * temperature_noise.get_noise_2d(1 * nx, 1 * ny)
			var second_temp_freq = 0.5 * temperature_noise.get_noise_2d(2 * nx, 2 * ny)
			var third_temp_freq = 0.25 * temperature_noise.get_noise_2d(4 * nx, 4 * ny)
			var t = first_temp_freq + second_temp_freq + third_temp_freq
			var temp_offset = t * adjusted_temp_noise_variation
			var distance_to_equator = abs( y - (world_size.y / 2) )
			var total_temp_variance = abs(temp_at_pole - temp_at_equator)
			var average_temp_change_per_lat_tile = total_temp_variance / world_size.y
			var lat_adjusted_temp = temp_at_equator - (pow(average_temp_change_per_lat_tile * distance_to_equator,1.15))
			var celsius = clamp(lat_adjusted_temp + temp_offset,temp_at_pole + rand_range(-5.0,5.0), temp_at_equator + (rand_range(-5.0,5.0)))
			data_entry["temperature"] = celsius
			temperature_map[Vector2(x,y)] = celsius
			combined_map_data[Vector2(x,y)] = data_entry
	_create_map()
	
func _generate_heat_map():
	if heat_map:
		heat_map = false
		$heat_map.hide()
		$map.set_modulate(Color(1.0,1.0,1.0,1.0))
		$map.set_self_modulate(Color(1.0,1.0,1.0,1.0))
		return
	else:
		heat_map = true
		$heat_map.show()
		$map.set_modulate(Color(1.0,1.0,1.0,0.4))
		$map.set_self_modulate(Color(1.0,1.0,1.0,0.4))

func _create_map():
	var total = world_size.x * world_size.y
	var ocean_tiles = 0
	for key in combined_map_data.keys():
		var temp_there = temperature_map[key]
		var kelvin_there = temp_there + 273.15
		var index = 0
		if kelvin_there > 205 and kelvin_there < 224:
			index = 1
		elif kelvin_there >= 224 and kelvin_there < 239:
			index = 2
		elif kelvin_there >= 239 and kelvin_there < 256:
			index = 3
		elif kelvin_there >= 256 and kelvin_there < 271:
			index = 4
		elif kelvin_there >= 271 and kelvin_there < 288:
			index = 5
		elif kelvin_there >= 288 and kelvin_there < 305:
			index = 6
		elif kelvin_there >= 305:
			index = 7 
		$heat_map.set_cellv(key,index)
		var data_dict = combined_map_data[key]
		var water = false
		# elevation
		if data_dict["elevation"] < water_threshold:
			map_tilemap.set_cellv(key,deep_water)
			ocean_tiles += 1
			water = true
		elif data_dict["elevation"] < shallow_water_threshold:
			map_tilemap.set_cellv(key,shallow_water)
			ocean_tiles +=1
			water = true
		elif data_dict["elevation"] < land_threshold:
			map_tilemap.set_cellv(key,grassland)
			water = false
		elif data_dict["elevation"] < mountain_threshold:
			map_tilemap.set_cellv(key,mountain)
			water = false
		elif data_dict["elevation"] >= mountain_threshold:
			map_tilemap.set_cellv(key,ice)
			water = false
		#moisture and temp
		if !water:
			if data_dict["moisture"] < desert_threshold and data_dict["temperature"] > 25:
				map_tilemap.set_cellv(key,desert)
			elif data_dict["moisture"] < grassland_threshold:
				map_tilemap.set_cellv(key,grassland)
			elif data_dict["moisture"] < forest_threshold:
				map_tilemap.set_cellv(key,forest)
			elif data_dict["moisture"] < jungle_threshold and data_dict["temperature"] > 20:
				map_tilemap.set_cellv(key,jungle)
			elif data_dict["moisture"] > jungle_threshold and data_dict["temperature"] > 10:
				map_tilemap.set_cellv(key,swamp)
			var distance_to_equator = abs( key.y - (world_size.y / 2) )
			var chance = 534.8 + (0.8 - 534.8)/pow(1 + (distance_to_equator/215.8),7.0)
			if chance > 100.0:
				chance = 100.0
			var dice_roll = rng.randi() % 100 + snow_chance_reduction
			dice_roll += (data_dict["temperature"] * abs(data_dict["temperature"]))
			if dice_roll < chance:
				map_tilemap.set_cellv(key,ice)
		data_dict["name"] = map_tilemap.get_tileset().tile_get_name(map_tilemap.get_cellv(key))
	print("percentage water coverage = " + str((ocean_tiles / total) * 100.0))

func _adjusted_noise_range(value):
	return (value + 1) / 2

