extends RetroHubSupportModel

var support_mat : StandardMaterial3D

func _ready():
	mesh_path = $"Model/Object003_01 - Default_0"
	surface_idx = 1
	extract_material()
