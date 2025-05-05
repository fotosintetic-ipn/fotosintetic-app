extends Node2D

@export var server_url: String = "http://127.0.0.1:18080"
@export var fotosintetic_url: String = "http://192.168.4.1"
var device_name: String
var password: String

func _ready():
	return

func _process(_delta):
	return

func _on_device_connection_send_pressed():
	var ssid = $device_connection/form/ssid.text
	var wifi_password = $device_connection/form/password.text
	
	if ssid == "" || wifi_password == "":
		return
	
	$device_connection/request.request(fotosintetic_url + "/connect?ssid=" + ssid + "&password=" + wifi_password, PackedStringArray(), HTTPClient.METHOD_POST)

func _on_device_connection_already_connected_pressed():
	_on_device_connection_request_completed(1, 200, 1, 1)

func _on_device_connection_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		$device_connection/label.modulate = Color(1, 0, 0)
		$device_connection/status.modulate = Color(1, 0, 0)
		$device_connection/status.text = body.get_string_from_utf8()
		$server/register_device.disabled = true
		return
	
	$device_connection/label.modulate = Color(0, 1, 0)
	$device_connection/status.modulate = Color(0, 1, 0)
	$device_connection/status.text = "200 OK"
	
	$server/register_device.disabled = false
	$server/log_in.disabled = false
	$server/form/password.editable = true
	$server/form/device_name.editable = true

func _on_server_register_device_pressed():
	device_name = $server/form/device_name.text
	password = $server/form/password.text
	
	if device_name == "" || password == "":
		return
	
	$server/request.request(server_url + "/register_device?device_name=" + device_name + "&password=" + password, PackedStringArray(), HTTPClient.METHOD_POST)

func _on_server_log_in_pressed():
	device_name = $server/form/device_name.text
	password = $server/form/password.text
	
	if device_name == "" || password == "":
		return
	
	$server/request.request(server_url + "/validate_credentials?device_name=" + device_name + "&password=" + password, PackedStringArray(), HTTPClient.METHOD_GET)

func _on_server_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		$server/label.modulate = Color(1, 0, 0)
		$server/status.modulate = Color(1, 0, 0)
		$server/status.text = body.get_string_from_utf8()
		$device_credentials/send.disabled = true
		$device_credentials/form/phone_number.editable = false
		return
	
	$server/label.modulate = Color(0, 1, 0)
	$server/status.modulate = Color(0, 1, 0)
	$server/status.text = "200 OK"
	$device_credentials/send.disabled = false
	$device_credentials/already_logged_in.disabled = false

func _on_send_credentials_pressed():
	$device_credentials/request.request(fotosintetic_url + "/credentials?device_name=" + device_name + "&password=" + password, PackedStringArray(), HTTPClient.METHOD_POST)

func _on_device_credentials_already_logged_in_pressed():
	_on_device_credentials_request_completed(1, 200, 1, 1)

func _on_device_credentials_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		$device_credentials/label.modulate = Color(1, 0, 0)
		$device_credentials/status.modulate = Color(1, 0, 0)
		$device_credentials/status.text = body.get_string_from_utf8()
		return
	
	$device_credentials/label.modulate = Color(0, 1, 0)
	$device_credentials/status.modulate = Color(0, 1, 0)
	$device_credentials/status.text = "200 OK"
	$next.disabled = false

func _on_next_pressed():
	DirAccess.remove_absolute("user://data.dat")
	
	var file = FileAccess.open("user://data.dat", FileAccess.WRITE)
	file.store_string(device_name + "\n")
	file.store_string(password)
	file.close()
	
	get_tree().change_scene_to_file("res://scenes/graph.tscn")
