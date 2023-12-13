extends Node2D

@export var server_url = ""
@export var oxim_url = "http://192.168.4.1"
var username: String
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
	
	$device_connection/request.request(oxim_url + "/connect?ssid=" + ssid + "&password=" + wifi_password, PackedStringArray(), HTTPClient.METHOD_POST)

func _on_device_connection_already_connected_pressed():
	_on_device_connection_request_completed(1, 200, 1, 1)

func _on_device_connection_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		$device_connection/label.modulate = Color(1, 0, 0)
		$device_connection/status.modulate = Color(1, 0, 0)
		$device_connection/status.text = body.get_string_from_utf8()
		$server/create_account.disabled = true
		return
	
	$device_connection/label.modulate = Color(0, 1, 0)
	$device_connection/status.modulate = Color(0, 1, 0)
	$device_connection/status.text = "200 OK"
	
	$server/create_account.disabled = false
	$server/log_in.disabled = false
	$server/form/password.editable = true
	$server/form/username.editable = true

func _on_server_create_account_pressed():
	username = $server/form/username.text
	password = $server/form/password.text
	
	if username == "" || password == "":
		return
	
	$server/request.request(server_url + "/create_account?username=" + username + "&password=" + password, PackedStringArray(), HTTPClient.METHOD_POST)

func _on_server_log_in_pressed():
	username = $server/form/username.text
	password = $server/form/password.text
	
	if username == "" || password == "":
		return
	
	$server/request.request(server_url + "/validate_credentials?username=" + username + "&password=" + password, PackedStringArray(), HTTPClient.METHOD_GET)

func _on_server_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		$server/label.modulate = Color(1, 0, 0)
		$server/status.modulate = Color(1, 0, 0)
		$server/status.text = body.get_string_from_utf8()
		$device_credentials/send.disabled = true
		return
	
	$server/label.modulate = Color(0, 1, 0)
	$server/status.modulate = Color(0, 1, 0)
	$server/status.text = "200 OK"
	$device_credentials/send.disabled = false
	$device_credentials/already_logged_in.disabled = false

func _on_send_credentials_pressed():
	$device_credentials/request.request(oxim_url + "/credentials?username=" + username + "&password=" + password, PackedStringArray(), HTTPClient.METHOD_POST)

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
	file.store_string(username + "\n")
	file.store_string(password)
	file.close()
	
	get_tree().change_scene_to_file("res://scenes/graph.tscn")
