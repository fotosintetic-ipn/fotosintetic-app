extends Node2D

@onready var chart_scn: PackedScene = load("res://addons/easy_charts/control_charts/chart.tscn")
var soil_chart: Chart
var ambient_chart: Chart
var trunk_chart: Chart

var ph_func: Function
var humidity_func: Function
var temperature_func: Function
var roll_func: Function
var pitch_func: Function
var moisture_func: Function
var wind_func: Function

var device_name
var password
@export var server_url = "http://127.0.0.1:18080"
var timer = 0

var response: Dictionary
var data_available: bool = false
var last_id = 0

var time: PackedFloat32Array = ArrayOperations.multiply_float(range(0, 101, 1), 1.0)

var ph: Array = ArrayOperations.multiply_float(range(0, 101, 1), 1.0)
var ambient_humidity: Array = ArrayOperations.multiply_float(range(0, 101, 1), 1.0)
var ambient_temperature: Array = ArrayOperations.multiply_float(range(0, 101, 1), 1.0)
var roll: Array = ArrayOperations.multiply_float(range(0, 101, 1), 1.0)
var pitch: Array = ArrayOperations.multiply_float(range(0, 101, 1), 1.0)
var moisture: Array = ArrayOperations.multiply_float(range(0, 101, 1), 1.0)
var wind_speed: Array = ArrayOperations.multiply_float(range(0, 101, 1), 1.0)

func _ready():
	soil_chart = chart_scn.instantiate()
	ambient_chart = chart_scn.instantiate()
	trunk_chart = chart_scn.instantiate()
	var size: Vector2 = Vector2(670, 450)
	var pos: Vector2 = Vector2(25, 25)
	soil_chart.size = size
	soil_chart.position = pos
	pos.y += 500
	ambient_chart.size = size
	ambient_chart.position = pos
	pos.y += 500
	trunk_chart.size = size
	trunk_chart.position = pos
	$".".add_child(soil_chart)
	$".".add_child(ambient_chart)
	$".".add_child(trunk_chart)
	
	var file = FileAccess.open("user://data.dat", FileAccess.READ)
	device_name = file.get_as_text().substr(0, file.get_as_text().find("\n"))
	password = file.get_as_text().substr(file.get_as_text().find("\n") + 1)
	
	get_records(10)
	
	var cp: ChartProperties = ChartProperties.new()
	cp.colors.frame = Color("#161a1d")
	cp.colors.background = Color.TRANSPARENT
	cp.colors.grid = Color("#283442")
	cp.colors.ticks = Color("#283442")
	cp.colors.text = Color.WHITE_SMOKE
	cp.draw_bounding_box = false
	cp.title = "Soil status"
	cp.x_label = "Time"
	cp.y_label = "Sensor values"
	cp.x_scale = 10
	cp.y_scale = 10
	cp.interactive = true
	cp.max_samples = 100
	ph_func = Function.new(time, ph, "pH", {
		color = Color(0, 0, 1),
		marker = Function.Marker.CIRCLE,
		type = Function.Type.LINE,
		interpolation = Function.Interpolation.SPLINE
	})
	humidity_func = Function.new(time, ambient_humidity, "Ambient Moisture", {
		color = Color(0, 0.5, 1),
		marker = Function.Marker.SQUARE,
		type = Function.Type.LINE,
		interpolation = Function.Interpolation.SPLINE
	})
	temperature_func = Function.new(time, ambient_temperature, "Ambient temperature", {
		color = Color(1, 0, 0),
		marker = Function.Marker.SQUARE,
		type = Function.Type.LINE,
		interpolation = Function.Interpolation.SPLINE
	})
	roll_func = Function.new(time, roll, "Roll", {
		color = Color(1, 0.5, 0),
		marker = Function.Marker.CROSS,
		type = Function.Type.LINE,
		interpolation = Function.Interpolation.SPLINE
	})
	pitch_func = Function.new(time, pitch, "Pitch", {
		color = Color(0.6, 0.2, 0.8),
		marker = Function.Marker.CROSS,
		type = Function.Type.LINE,
		interpolation = Function.Interpolation.SPLINE
	})
	moisture_func = Function.new(time, moisture, "Soil Moisture", {
		color = Color(0, 0.6, 0),
		marker = Function.Marker.CIRCLE,
		type = Function.Type.LINE,
		interpolation = Function.Interpolation.SPLINE
	})
	wind_func = Function.new(time, wind_speed, "Wind Speed", {
		color = Color(0.8, 0.8, 0.8),
		marker = Function.Marker.CIRCLE,
		type = Function.Type.LINE,
		interpolation = Function.Interpolation.SPLINE
	})
	
	soil_chart.plot([ph_func, moisture_func], cp)
	cp.title = "Ambient status"
	ambient_chart.plot([humidity_func, temperature_func, wind_func], cp)
	cp.title = "Trunk status"
	trunk_chart.plot([pitch_func, roll_func], cp)

func _process(delta):
	if(!data_available):
		timer += delta
		if(timer >= 15):
			get_records(10)
			timer = 0
		return
	
	ph = []
	ambient_humidity = []
	ambient_temperature = []
	roll = []
	pitch = []
	moisture = []
	wind_speed = []
	
	var dataset_length: int = response["data"].size()
	for i in range(1, dataset_length + 1, 1):
		for ii in range(0, response["data"][dataset_length - i]["ph"].size(), 1):
			ph.push_back(response["data"][dataset_length - i]["ph"][ii])
			ambient_humidity.push_back(response["data"][dataset_length - i]["ambient_humidity"][ii])
			ambient_temperature.push_back(response["data"][dataset_length - i]["ambient_temperature"][ii])
			roll.push_back(response["data"][dataset_length - i]["roll"][ii])
			pitch.push_back(response["data"][dataset_length - i]["pitch"][ii])
			moisture.push_back(response["data"][dataset_length - i]["moisture"][ii])
			wind_speed.push_back(response["data"][dataset_length - i]["wind_speed"][ii])
	
	while ph_func.count_points() > 0:
		ph_func.remove_point(0)
	while humidity_func.count_points() > 0:
		humidity_func.remove_point(0)
	while temperature_func.count_points() > 0:
		temperature_func.remove_point(0)
	while roll_func.count_points() > 0:
		roll_func.remove_point(0)
	while pitch_func.count_points() > 0:
		pitch_func.remove_point(0)
	while moisture_func.count_points() > 0:
		moisture_func.remove_point(0)
	while wind_func.count_points() > 0:
		wind_func.remove_point(0)
	
	for i in range(0, ph.size(), 1):
		ph_func.add_point(i, ph[i])
		humidity_func.add_point(i, ambient_humidity[i])
		temperature_func.add_point(i, ambient_temperature[i])
		roll_func.add_point(i, roll[i])
		pitch_func.add_point(i, pitch[i])
		moisture_func.add_point(i, moisture[i])
		wind_func.add_point(i, wind_speed[i])
		
	soil_chart.queue_redraw()
	soil_chart.visible = true
	ambient_chart.queue_redraw()
	ambient_chart.visible = true
	trunk_chart.queue_redraw()
	trunk_chart.visible = true
	data_available = false
	

func get_records(limit: int = -1):
	var parameters = ""
	
	if(limit != -1):
		parameters = "?limit=" + str(limit)
	
	var auth = "Authorization: Basic "
	auth += str(Marshalls.utf8_to_base64(device_name + ":" + password))
	
	$request.request(server_url + "/get_records" + parameters, [auth])
	
func _on_request_completed(_result, _response_code, _headers, body):
	response = JSON.parse_string(body.get_string_from_utf8())
	print(body.get_string_from_utf8())
	data_available = true
