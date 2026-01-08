extends Node3D

var cam_pilote: Camera3D
var cam_copilote: Camera3D

const HINTS = {
	"BoutonLanceDes": "Appuyer sur le bouton lancer les dés"
}

func _ready():
	print("--- [MAIN] INITIALISATION ---")
	get_tree().root.print_tree_pretty()
	
	# Find cameras robustly by scanning for name patterns
	for child in get_children():
		if "CamPilote" in child.name and not "CamCopilote" in child.name:
			cam_pilote = child
		elif "CamCopilote" in child.name:
			cam_copilote = child
	
	if cam_pilote: print("[MAIN] CamPilote trouvée : ", cam_pilote.name)
	else: print("[MAIN] ERREUR: CamPilote non trouvée dans l'arbre !")
	
	if cam_copilote: print("[MAIN] CamCopilote trouvée : ", cam_copilote.name)
	else: print("[MAIN] ERREUR: CamCopilote non trouvée dans l'arbre !")

	print("[MAIN] Local ID: ", multiplayer.get_unique_id())
	print("[MAIN] Local Role: ", GameManager.local_role)
	
	await get_tree().create_timer(0.2).timeout
	apply_initial_view()

func _physics_process(_delta):
	var cameraSource = get_viewport().get_camera_3d()
	if not cameraSource: return
	
	var center = get_viewport().size / 2
	var from = cameraSource.project_ray_origin(center)
	var to = from + cameraSource.project_ray_normal(center) * 10.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	
	var result = space_state.intersect_ray(query)
	var label = get_node_or_null("Crosshair/CenterContainer/VBoxContainer/InteractionLabel")
	
	if label:
		if result:
			var target = result.collider
			var target_name = target.name
			
			if target is Area3D and result.has("shape"):
				var child_count = target.get_child_count()
				if result.shape < child_count:
					var shape_node = target.get_child(result.shape)
					if shape_node:
						target_name = shape_node.name
						# Deep DEBUG: print("Vise : ", target_name)
			
			if HINTS.has(target_name):
				label.text = HINTS[target_name]
			else:
				label.text = ""
		else:
			label.text = ""

func apply_initial_view():
	print("[MAIN] Application de la vue pour: ", GameManager.local_role)
	switch_player(GameManager.local_role)
	
	var role_label = get_node_or_null("Crosshair/RoleLabel")
	if role_label:
		role_label.text = "RÔLE : " + GameManager.local_role
	else:
		print("[MAIN] ERREUR: RoleLabel non trouvé. Chemin vérifié: Crosshair/RoleLabel")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			switch_player("PILOT")
		elif event.keycode == KEY_2:
			switch_player("COPILOT")

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var camera = get_viewport().get_camera_3d()
		if not camera: return
		
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 10.0
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.collide_with_areas = true
		query.collide_with_bodies = false
		
		var result = space_state.intersect_ray(query)
		if result:
			var target = result.collider
			var target_name = target.name
			
			if target is Area3D and result.has("shape"):
				var child_count = target.get_child_count()
				if result.shape < child_count:
					var shape_node = target.get_child(result.shape)
					if shape_node:
						target_name = shape_node.name
			
			print("[MAIN] Clic sur: ", target_name)
			handle_interaction(target_name)

func switch_player(player: String):
	GameManager.switch_to_player(player)
	
	if player == "PILOT":
		if cam_pilote:
			cam_pilote.current = true
			if cam_copilote: cam_copilote.current = false
		else:
			print("[MAIN] ERREUR: cam_pilote est NULL")
	else:
		if cam_copilote:
			cam_copilote.current = true
			if cam_pilote: cam_pilote.current = false
		else:
			print("[MAIN] ERREUR: cam_copilote est NULL")

func handle_interaction(node_name: String):
	print("[MAIN] Interaction avec: ", node_name)
	if node_name == "BoutonLanceDes":
		GameManager.confirm_ready(GameManager.current_player)
