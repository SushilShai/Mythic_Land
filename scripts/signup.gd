extends Control

@onready var username: LineEdit = $Username
@onready var email: LineEdit = $Email
@onready var password: LineEdit = $Password
@onready var confirm_password: LineEdit = $Conform_Password
@onready var signup_button: Button = $SignupButton
@onready var signup_camera: Camera2D = $SignupCamera
@onready var signup_request: HTTPRequest = $SignupRequest
@onready var status_label: RichTextLabel = $RichTextLabel
@onready var login_button: Button = $loginButton
@onready var login_camera: Camera2D = $"../Login/LoginCamera"

func _ready():
	signup_button.pressed.connect(_on_signup_pressed)
	signup_request.request_completed.connect(_on_signup_response)
	login_button.pressed.connect(_on_login_pressed)

func _on_login_pressed():
	login_camera.make_current()

func _on_signup_pressed():
	var user = username.text.strip_edges()
	var mail = email.text.strip_edges()
	@warning_ignore("confusable_local_usage", "shadowed_variable")
	var password = password.text.strip_edges()
	var confirm = confirm_password.text.strip_edges()

	if password != confirm:
		print('Passwords do not match')
		return

	var payload = {
		"username": user,
		"email": mail,
		"password": password
	}

	var headers = ["Content-Type: application/json"]
	var json_body = JSON.stringify(payload)

	print("creating account ...")
	signup_request.request(
		"http://127.0.0.1:8000/api/signup/",
		headers,
		HTTPClient.METHOD_POST,
		json_body
	)

@warning_ignore("unused_parameter")
func _on_signup_response(result, response_code, headers, body):
	var response_text = body.get_string_from_utf8()
	var json = JSON.parse_string(response_text)

	if response_code == 201:
		print("Signup success:", json)
		login_camera.make_current()
	else:
		print("Signup failed:", response_code, json)
