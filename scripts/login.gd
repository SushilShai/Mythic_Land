extends Control

@onready var email_field: LineEdit = $Email
@onready var password_field: LineEdit = $Password
@onready var login_button: Button = $LoginButton
@onready var signup_button: Button = $SignupButton
@onready var login_camera: Camera2D = $LoginCamera
@onready var login_request: HTTPRequest = $LoginRequest
@onready var status_label: RichTextLabel = $RichTextLabel
@onready var main_camera: Camera2D = $"../main/mainCamera"


func _ready():
	login_button.pressed.connect(_on_login_pressed)
	signup_button.pressed.connect(_on_signup_pressed)
	login_request.request_completed.connect(_on_login_response)

func _on_login_pressed():

	var email = email_field.text.strip_edges()
	var password = password_field.text.strip_edges()

	if email == "" or password == "":
		status_label.text = "[color=red]Username and password required[/color]"
		return

	print(email)
	print(password)
	var payload = {
		"email": email,
		"password": password
	}

	var headers = ["Content-Type: application/json"]
	var json_body = JSON.stringify(payload)

	status_label.text = "[color=yellow]Logging in...[/color]"

	login_request.request(
		"http://127.0.0.1:8000/api/login/",
		headers,
		HTTPClient.METHOD_POST,
		json_body
	)

func _on_signup_pressed():
	$"../Signup/SignupCamera".make_current()

@warning_ignore("unused_parameter")
func _on_login_response(result, response_code, headers, body):
	var response_text = body.get_string_from_utf8()
	var json = JSON.parse_string(response_text)

	if response_code == 200:
		print("Login success:", json)
		main_camera.make_current()
		
	else:
		status_label.text = "[color=red]Login failed: %s[/color]" % response_code
		print("Login failed:", response_code, json)
