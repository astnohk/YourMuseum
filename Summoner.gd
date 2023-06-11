extends Node3D

var prompt = "a ube ice cone"

const RKEY_PATH = "path"
const RKEY_KEY = "key"
const RKEY_RESPONSE_DATA = "response_data"
const RKEY_DATA = "data"

const API_REQUEST = "/request"
const API_GET_RESULT = "/getResult"

var client = null
var requesting = false
const url = "http://127.0.0.1:50000"
var requestedKey = null
var count = 0

var createdMeshes = []


# Called when the node enters the scene tree for the first time.
func _ready():
	client = HTTPRequest.new()
	add_child(client)
	client.request_completed.connect(_on_request_completed)

	_request(
			"%s%s?fileformat=json" % [url, API_REQUEST],
			[
				"Content-Type: text/plain",
			],
			HTTPClient.METHOD_POST,
			prompt)


func _request(url, headers=[], method=HTTPClient.METHOD_GET, request_data=""):
	if requesting:
		print("There are a continuing request...")
		return
	requesting = true
	client.request(url, headers, method, request_data)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	count += 1
	if ((count % 200) == 0
			and client):
		if requestedKey:
			_request("%s%s?key=%s" % [url, API_GET_RESULT, requestedKey])
	
	for mesh in createdMeshes:
		mesh.rotate_x(0.05)
		mesh.rotate_z(0.01)


func _on_request_completed(result, response_code, headers, body):
	requesting = false
	print(result)
	print(response_code)
	print(headers)
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		if response.has(RKEY_PATH) and response[RKEY_PATH] == API_REQUEST:
			if response.has(RKEY_RESPONSE_DATA):
				requestedKey = response[RKEY_RESPONSE_DATA].get(RKEY_KEY)
		else:
			if response.has(RKEY_RESPONSE_DATA) and response[RKEY_RESPONSE_DATA].has(RKEY_DATA):
				spawn(response[RKEY_RESPONSE_DATA][RKEY_DATA])
			requestedKey = null


func spawn(data):
	var mesh = ArrayMesh.new()
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	var verts = PackedVector3Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	# Assign geometry info from JSON to the ArrayMesh
	for v in data["verts"]["buffer"]:
		verts.push_back(Vector3(v[0], v[1], v[2]))
	for c in data["colors"]["buffer"]:
		colors.push_back(Color(c[0], c[1], c[2], 0.7))
	for t in data["triangles"]["buffer"]:
		indices.push_back(t[0])
		indices.push_back(t[1])
		indices.push_back(t[2])
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_COLOR] = colors
	surface_array[Mesh.ARRAY_INDEX] = indices
	# Add new surface from JSON to the ArrayMesh
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	# Set vertex color material to the ArrayMesh
	var material = load("res://M_VertexColor.tres")
	mesh.surface_set_material(0, material)
	# Create new MeshInstance3D and assign the ArrayMesh as Mesh
	var m = MeshInstance3D.new()
	m.mesh = mesh
	# Spawn in the 3D world
	createdMeshes.append(m)
	add_child(m)
