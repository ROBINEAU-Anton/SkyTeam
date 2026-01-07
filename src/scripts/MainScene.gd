extends Node3D

func _ready():
	print("--- SCÈNE MAIN CHARGÉE (ROOT) ---")
	print("Enfants de la scène : ")
	for child in get_children():
		print(" - ", child.name)
