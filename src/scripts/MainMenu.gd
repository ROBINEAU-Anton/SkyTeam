extends Control

func _on_play_button_pressed():
	print("Bouton VOLER pressé - Changement de scène...")
	var err = get_tree().change_scene_to_file("res://src/scenes/RoleSelection.tscn")
	if err != OK:
		print("ERREUR de changement de scène vers Sélection des Rôles : ", err)

func _on_quit_button_pressed():
	get_tree().quit()
