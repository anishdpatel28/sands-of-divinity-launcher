extends Button

var exe_link = "https://onedrive.live.com/download?resid=7FB2F93B04562985!334&authkey=!AF99RiMuO4YG06E"
var pck_link = "https://onedrive.live.com/download?resid=7FB2F93B04562985!330&authkey=!AM1jpv89qxf6aLU"
var dll_link = "https://onedrive.live.com/download?resid=7FB2F93B04562985!332&authkey=!AJA8p3EOQfsOg0k"
var version_link = "https://onedrive.live.com/download?resid=7FB2F93B04562985!327&authkey=!AMSLENQMBtlLuT0&ithint=file%2ctxt"

var exe_path = "user://Sands of Divinity.exe"
var pck_path = "user://Sands of Divinity.pck"
var dll_path = "user://Sands of Divinity.dll"
var version_path = "user://version.txt"

var http_request: HTTPRequest
var current_download_path: String
var current_download_is_version: bool

func _ready() -> void:
	_verify_gamefiles()
	self.disabled = true

func file_exists(path: String) -> bool:
	return FileAccess.file_exists(path)

func _verify_gamefiles():
	# Check if files are complete
	if file_exists(exe_path) && file_exists(pck_path) && file_exists(dll_path) && file_exists(version_path):
		_download_file(version_link, version_path, true)
	else:
		_check_integrity()

func _download_file(link: String, path: String, just_version: bool):
	# Create an HTTP request node and connect its completion signal.
	http_request = HTTPRequest.new()
	add_child(http_request)
	
	self.text = "Downloading " + str(path.get_file())
	
	# Store the current path and whether it's just the version file
	current_download_path = path
	current_download_is_version = just_version
	
	# Use Callable to correctly connect the signal
	http_request.request_completed.connect(_install_file)
	
	# Handle Errors
	var error = http_request.request_raw(link)
	if error != OK:
		self.text = "Download Error: " + str(error)

# This is called once the download is complete
func _install_file(_result, _response_code, _headers, body):
	if current_download_is_version:
		var new_version = str(body.get_string_from_utf8())
		_compare_version(new_version)
		return
	
	DirAccess.remove_absolute(current_download_path)
	
	var file = FileAccess.open(current_download_path, FileAccess.WRITE)
	file.store_buffer(body)
	file.close()
	_check_integrity()

func _check_integrity():
	if !file_exists(exe_path):
		_download_file(exe_link, exe_path, false)
		print("no exe")
		return
	
	if !file_exists(version_path):
		_download_file(version_link, version_path, false)
		DirAccess.remove_absolute(pck_path)
		print("no version")
		return
	
	if !file_exists(pck_path):
		_download_file(pck_link, pck_path, false)
		print("no pck")
		return
	
	self.text = "Start Game!"
	self.disabled = false

func _compare_version(new_version):
	var file = FileAccess.open(version_path, FileAccess.READ)
	var cur_version = file.get_as_text()
	file.close()
	if int(new_version) > int(cur_version):
		DirAccess.remove_absolute(version_path)
	_check_integrity()

func _start_game():
	OS.shell_open(OS.get_user_data_dir() + "/Sands of Divinity.exe")

func _on_pressed() -> void:
	_start_game()
