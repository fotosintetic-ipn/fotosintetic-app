extends Node2D

@onready var chart: Chart = $Chart
var heartrate: Function
var spo2: Function

var username
var password
@export var server_url = ""
var timer = 0

var response: Dictionary
var data_available: bool = false
var last_id = 0
var time: PackedFloat32Array = ArrayOperations.multiply_float(range(0, 101, 1), 1.0)
var heartrate_value: Array = ArrayOperations.multiply_int(range(0, 101, 1), 1)
var spo2_value: Array = ArrayOperations.multiply_int(range(0, 101, 1), 1)

func _ready():
	var file = FileAccess.open("user://data.dat", FileAccess.READ)
	username = file.get_as_text().substr(0, file.get_as_text().find("\n"))
	password = file.get_as_text().substr(file.get_as_text().find("\n") + 1)
	
	print(username)
	print(password)
	
	get_records(-1, 99999, 10)
	
	var cp: ChartProperties = ChartProperties.new()
	cp.colors.frame = Color("#161a1d")
	cp.colors.background = Color.TRANSPARENT
	cp.colors.grid = Color("#283442")
	cp.colors.ticks = Color("#283442")
	cp.colors.text = Color.WHITE_SMOKE
	cp.draw_bounding_box = false
	cp.title = "Heartrate"
	cp.x_label = "Time"
	cp.y_label = "Sensor values"
	cp.x_scale = 10
	cp.y_scale = 10
	cp.interactive = true
	cp.max_samples = 100
	
	heartrate = Function.new(time, heartrate_value, "Heartrate",
		{ 
			color = Color("#36a2eb"), 		# The color associated to this function
			marker = Function.Marker.CIRCLE, 	# The marker that will be displayed for each drawn point (x,y)
											# since it is `NONE`, no marker will be shown.
			type = Function.Type.LINE, 		# This defines what kind of plotting will be used, 
											# in this case it will be a Linear Chart.
			interpolation = Function.Interpolation.STAIR	# Interpolation mode, only used for 
															# Line Charts and Area Charts.
		}
	)
	spo2 = Function.new(time, spo2_value, "spo2",
		{
			color = Color(1, 0, 0),
			marker = Function.Marker.CIRCLE,
			type = Function.Type.LINE,
			interpolation = Function.Interpolation.STAIR
		}
	)
	
	chart.plot([heartrate, spo2], cp)

func _process(delta):
	if(!data_available):
		timer += delta
		if(timer >= 15):
			get_records(-1, 99999, 10)
			timer = 0
		return
	
	heartrate_value = []
	spo2_value = []
	var idx = 0
	
	for i in range(0, response["data"].size(), 1):
		for ii in range(0, response["data"][i]["heartrate"].size(), 1):
			heartrate_value.push_back(response["data"][i]["heartrate"][ii])
			spo2_value.push_back(response["data"][i]["spo2"][ii])
			
	print("heartrate ", heartrate_value)
	print("spo2 ", spo2_value)
	
	for i in heartrate.count_points():
		heartrate.remove_point(0)
		spo2.remove_point(0)
	
	for i in range(0, heartrate_value.size(), 1):
		heartrate.add_point(i, heartrate_value[i])
		spo2.add_point(i, spo2_value[i])
		
	chart.queue_redraw()
	chart.visible = true
	data_available = false
	

func get_records(after: int = -1, before: int = -1, limit: int = -1):
	if((after == -1 && before == -1) || (after != -1 && before != -1)):
		var ret: Dictionary
		return ret
	
	var parameters = "?"
	if(after != -1):
		parameters += "after=" + str(after)
	else:
		parameters += "before=" + str(before)
	
	if(limit != -1):
		parameters += "&limit=" + str(limit)
	
	var auth = "Authorization: Basic "
	auth += str(Marshalls.utf8_to_base64(username + ":" + password))
	
	$request.request(server_url + "/get_records" + parameters, [auth])
	
func _on_request_completed(result, response_code, headers, body):
	response = JSON.parse_string(body.get_string_from_utf8())
	data_available = true
