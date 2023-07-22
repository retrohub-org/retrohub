extends RetroHubSupportModel

var support_mat : StandardMaterial3D

func _ready():
	mesh_path = $Model/pPlane1_blinn1_0
	surface_idx = 0
	extract_material()
