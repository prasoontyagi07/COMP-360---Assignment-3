extends Node3D

# --- Export Variables ---
@export var image_size: int = 128
@export var noise_frequency: float = 0.03
@export var mesh_height_scale: float = 25.0
@export var mesh_xz_scale: float = 0.5		
@export var base_y_depth: float = -10.0

# --- Internal Variables ---
var heightmap_image: Image
var grid_size: int


# --- Ready Function ---
func _ready():
	var generated_image: Image = generate_noise_image()
	
	if generated_image != null:
		heightmap_image = generated_image
		grid_size = heightmap_image.get_width() + 1
		print("Heightmap loaded. Grid size will be %dx%d vertices." % [grid_size, grid_size])
		
		save_image_to_disk(heightmap_image)
		
		create_landscape_mesh()
	else:
		push_error("Failed to generate heightmap image. Cannot create landscape.")


# --- Noise Generation Function (Step 1) ---
func generate_noise_image() -> Image:
	print("Generating FastNoiseLite image...")

	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_octaves = 4
	noise.frequency = noise_frequency

	var image = Image.create(image_size, image_size, false, Image.FORMAT_RF)

	for y in range(image_size):
		for x in range(image_size):
			var noise_value = noise.get_noise_2d(x, y)
			var color_value = (noise_value + 1.0) * 0.5
			image.set_pixel(x, y, Color(color_value, color_value, color_value))
			
	return image
	
# --- Helper Function to save the generated image
func save_image_to_disk(image: Image):
	var error = image.save_png("res://heightmap.png")
	if error != OK:
		print("Error saving image: ", error)
	else:
		print("Successfully saved heightmap.png with size %dx%d" % [image_size, image_size])


# --- Mesh Generation Function (Fixed with manual vertex counter) ---
func create_landscape_mesh():
	# 1. Create a container for the mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "LandscapeMesh"
	add_child(mesh_instance)

	# 2. Use SurfaceTool to build the geometry data
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 2a. Manual counter for vertex indexing
	var vertex_counter = 0

	# Define color stops for the gradient
	var color_grass = Color("#4a6a3b")
	var color_rock = Color("#808080")
	var color_snow = Color("#ffffff")
	
	# --- 3. GENERATE TOP SURFACE VERTICES ---
	
	for z in range(grid_size):
		for x in range(grid_size):
			
			var x_pos = float(x) * mesh_xz_scale
			var z_pos = float(z) * mesh_xz_scale
			
			var image_x = clamp(x, 0, image_size - 1)
			var image_y = clamp(z, 0, image_size - 1)
			var color_pixel = heightmap_image.get_pixel(image_x, image_y)
			var pixel_value = color_pixel.r
			
			var y_height = pixel_value * mesh_height_scale
			
			var vertex_color: Color
			
			if pixel_value < 0.2:
				vertex_color = color_grass.lerp(color_rock, pixel_value / 0.2)
			elif pixel_value < 0.5:
				vertex_color = color_rock.lerp(color_snow, (pixel_value - 0.2) / 0.3)
			else:
				vertex_color = color_snow.lerp(color_rock, (pixel_value - 0.5) * 2.0)
				
			st.set_color(vertex_color)
			
			var vertex_position = Vector3(x_pos, y_height, z_pos)
			
			var u = float(x) / (grid_size - 1.0)
			var v = float(z) / (grid_size - 1.0)
			st.set_uv(Vector2(u, v))
			st.add_vertex(vertex_position)
			# Increment the counter for every vertex added
			vertex_counter += 1

	# 4. Generate Triangles (Indices for Top Surface)
	for z in range(image_size):
		for x in range(image_size):
			var v0 = z * grid_size + x
			var v1 = z * grid_size + (x + 1)
			var v2 = (z + 1) * grid_size + (x + 1)
			var v3 = (z + 1) * grid_size + x

			st.add_index(v0)
			st.add_index(v1)
			st.add_index(v3)

			st.add_index(v3)
			st.add_index(v1)
			st.add_index(v2)
			
	# --- 5. GENERATE BOTTOM CAP (FIX FOR HOLLOW LOOK) ---
	var x_max = float(image_size) * mesh_xz_scale
	var z_max = float(image_size) * mesh_xz_scale
	var base_y = base_y_depth

	# Use the current counter value to mark the start of the bottom vertices
	var start_vertex_index = vertex_counter 
	
	# Set a solid, dark color for the bottom and sides
	var base_color = Color(0.1, 0.1, 0.1) 
	st.set_color(base_color)
	
	# 5a. Bottom Cap Vertices
	st.set_uv(Vector2(0, 0))
	st.add_vertex(Vector3(0, base_y, 0)) # v_b_00 (Index 0 relative to start)
	
	st.set_uv(Vector2(1, 0))
	st.add_vertex(Vector3(x_max, base_y, 0)) # v_b_x0 (Index 1 relative to start)
	
	st.set_uv(Vector2(1, 1))
	st.add_vertex(Vector3(x_max, base_y, z_max)) # v_b_xx (Index 2 relative to start)
	
	st.set_uv(Vector2(0, 1))
	st.add_vertex(Vector3(0, base_y, z_max)) # v_b_0x (Index 3 relative to start)
	
	# 5b. Bottom Cap Indices (Adjusted to use the base index)
	var v_b_00 = start_vertex_index + 0
	var v_b_x0 = start_vertex_index + 1
	var v_b_xx = start_vertex_index + 2
	var v_b_0x = start_vertex_index + 3
	
	# First Triangle
	st.add_index(v_b_00)
	st.add_index(v_b_0x)
	st.add_index(v_b_x0)
	
	# Second Triangle
	st.add_index(v_b_x0)
	st.add_index(v_b_0x)
	st.add_index(v_b_xx)
	
	# 6. Finalize the Mesh
	st.generate_normals()
	var array_mesh = st.commit()

	# 7. Apply the Mesh to the MeshInstance3D
	mesh_instance.mesh = array_mesh
	
	# Optional: Center the mesh for easier viewing
	mesh_instance.global_position = Vector3(
		-image_size * mesh_xz_scale / 2.0,	
		0,	
		-image_size * mesh_xz_scale / 2.0
	)
	
	# 8. Add Material and Texture
	add_texture_and_material(mesh_instance)
	
	print("3D Landscape Mesh created successfully!")

# --- Texture Function ---
func add_texture_and_material(mesh_instance: MeshInstance3D):
	var texture = ImageTexture.create_from_image(heightmap_image)
	
	var material = StandardMaterial3D.new()
	
	material.albedo_texture = texture
	
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	
	material.roughness = 0.8
	material.metallic = 0.1
	
	mesh_instance.material_override = material
	print("Material finalized: Vertex Color and FastNoiseLite Texture combined.")
