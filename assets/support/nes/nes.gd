extends RetroHubSupportModel

var support_mat : SpatialMaterial

func _ready():
	mesh_path = $Model/pPlane1_blinn1_0
	surface_idx = 0
	extract_material()
