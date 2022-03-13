extends Spatial

func _ready():
	var head_material: SpatialMaterial = $Sphere2/Sphere.get_surface_material(0)
	head_material.albedo_color = head_material.albedo_color.linear_interpolate(Color.black, Time.deltaTime)
	$Sphere2/Sphere.set_surface_material(0, head_material)
	
	var body_material: SpatialMaterial = $Circle/Circle2.get_surface_material(0)
	body_material.albedo_color = body_material.albedo_color.linear_interpolate(Color.black, Time.deltaTime)
	$Circle/Circle2.set_surface_material(0, body_material)
