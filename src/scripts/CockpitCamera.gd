extends Camera3D

@export_group("Settings")
@export var sensitivity: float = 0.1
@export var min_yaw: float = -60.0
@export var max_yaw: float = 60.0
@export var min_pitch: float = -45.0
@export var max_pitch: float = 45.0

var rotation_x: float = 0.0
var rotation_y: float = 0.0

func _ready():
	print("--- SCRIPT CAMERA INITIALISÉ SUR ", name, " ---")
	# On capture la souris au démarrage si on veut que ce soit actif tout de suite
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Initialiser les angles avec la rotation actuelle de la caméra
	rotation_x = rotation_degrees.x
	rotation_y = rotation_degrees.y

func _input(event):
	if not is_current(): return
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# On accumule le mouvement
		# Inversion de l'axe Y pour un comportement naturel (lever la souris = regarder en haut)
		rotation_x -= event.relative.y * sensitivity
		rotation_y -= event.relative.x * sensitivity
		
		# Limites pour ne pas se tordre le cou
		rotation_x = clamp(rotation_x, min_pitch, max_pitch)
		rotation_y = clamp(rotation_y, min_yaw, max_yaw)
		
		# Application de la rotation
		rotation_degrees.x = rotation_x
		rotation_degrees.y = rotation_y
		
	# Gestion du toggle de la souris
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
