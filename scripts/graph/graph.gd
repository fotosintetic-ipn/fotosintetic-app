extends Node2D

@onready var chart: Chart = $Chart

var to_plot: Array
var ph: Function

var device_name
var password
@export var server_url = "http://127.0.0.1:18080"
var timer = 0

var response: Dictionary
var data_available: bool = false
var last_id = 0
var time: PackedFloat32Array = ArrayOperations.multiply_float(range(0, 101, 1), 1.0)
var ph_value: Array = ArrayOperations.multiply_float(range(0, 101, 1), 1)

func _ready():
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
	cp.title = "pH"
	cp.x_label = "Time"
	cp.y_label = "Sensor values"
	cp.x_scale = 10
	cp.y_scale = 10
	cp.interactive = true
	cp.max_samples = 100
	
	ph = Function.new(time, ph_value, "pH",
		{ 
			color = Color(0, 0, 1), 		# The color associated to this function
			marker = Function.Marker.CIRCLE, 	# The marker that will be displayed for each drawn point (x,y)
											# since it is `NONE`, no marker will be shown.
			type = Function.Type.LINE, 		# This defines what kind of plotting will be used, 
											# in this case it will be a Linear Chart.
			interpolation = Function.Interpolation.STAIR	# Interpolation mode, only used for 
															# Line Charts and Area Charts.
		}
	)
	
	
	chart.plot([ph], cp)

func _process(delta):
	if(!data_available):
		timer += delta
		if(timer >= 15):
			get_records(10)
			timer = 0
		return
	
	ph_value = []
	
	var dataset_length: int = response["data"].size()
	for i in range(1, dataset_length + 1, 1):
		for ii in range(0, response["data"][dataset_length - i]["ph"].size(), 1):
			ph_value.push_back(response["data"][dataset_length - i]["ph"][ii])
			print(response["data"][dataset_length - i]["ph"][ii])
	
	for i in ph.count_points():
		ph.remove_point(0)
	
	for i in range(0, ph_value.size(), 1):
		ph.add_point(i, ph_value[i])
		
	chart.queue_redraw()
	chart.visible = true
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
