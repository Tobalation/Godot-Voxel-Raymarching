@tool
class_name VoxelModel
extends MeshInstance3D

const VOXEL_MAT = preload("res://addons/VoxelRaymarcher/voxel_mat.tres")

@export var voxels : Texture3D:
	get:
		return (get_surface_override_material(0) as ShaderMaterial).get_shader_parameter("voxel_data")
	set(value):
		(get_surface_override_material(0) as ShaderMaterial).set_shader_parameter("voxel_data", value)
		(get_surface_override_material(0) as ShaderMaterial).set_shader_parameter("voxel_longest_diagonal", _get_longest_diagonal(value))
		_rebuild_mesh()
		notify_property_list_changed()

@export_range(0.01, 100.0, 0.01) var voxel_scale : float = 1.0:
	get:
		return (get_surface_override_material(0) as ShaderMaterial).get_shader_parameter("voxel_scale")
	set(value):
		(get_surface_override_material(0) as ShaderMaterial).set_shader_parameter("voxel_scale", value)
		_rebuild_mesh()
		notify_property_list_changed()
		

func _rebuild_mesh() -> void:
	var voxels := self.voxels
	if voxels == null:
		mesh = null
		return
	var box : BoxMesh = BoxMesh.new()
	box.flip_faces = true
	box.size = Vector3(voxels.get_width(), voxels.get_height(), voxels.get_depth()) * voxel_scale
	mesh = box

func _get_longest_diagonal(voxels : Texture3D) -> int:
	var longest_diagonal : int = 0
	if voxels:
		longest_diagonal = sqrt(voxels.get_width() ** 2 + voxels.get_height() ** 2 + voxels.get_depth() ** 2)
	return longest_diagonal

func _enter_tree() -> void:
	if Engine.is_editor_hint() && mesh == null:
		var box : BoxMesh = BoxMesh.new()
		box.flip_faces = true
		mesh = box
		set_surface_override_material(0, VOXEL_MAT)
