extends Control

@onready var pilot_select_button = $CenterContainer/VBoxContainer/RoleUI/HBoxContainer/PilotPanel/VBoxContainer/PilotSelectButton
@onready var pilot_ready_button = $CenterContainer/VBoxContainer/RoleUI/HBoxContainer/PilotPanel/VBoxContainer/PilotReadyButton
@onready var copilot_select_button = $CenterContainer/VBoxContainer/RoleUI/HBoxContainer/CopilotPanel/VBoxContainer/CopilotSelectButton
@onready var copilot_ready_button = $CenterContainer/VBoxContainer/RoleUI/HBoxContainer/CopilotPanel/VBoxContainer/CopilotReadyButton
@onready var start_button = $CenterContainer/VBoxContainer/StartButton

@onready var network_ui = $CenterContainer/VBoxContainer/NetworkUI
@onready var role_ui = $CenterContainer/VBoxContainer/RoleUI

var pilot_ready = false
var copilot_ready = false
var pilot_peer_id = 0
var copilot_peer_id = 0

func _ready():
	update_ui()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id):
	print("Peer connected: ", id)
	if multiplayer.is_server():
		sync_state.rpc(pilot_peer_id, copilot_peer_id, pilot_ready, copilot_ready)

func _on_peer_disconnected(id):
	if multiplayer.is_server():
		if pilot_peer_id == id: pilot_peer_id = 0; pilot_ready = false
		if copilot_peer_id == id: copilot_peer_id = 0; copilot_ready = false
		sync_state.rpc(pilot_peer_id, copilot_peer_id, pilot_ready, copilot_ready)

func _on_host_button_pressed():
	if GameManager.host_game() == OK:
		update_ui()

func _on_join_button_pressed():
	var ip = $CenterContainer/VBoxContainer/NetworkUI/IPEdit.text
	if ip == "": ip = "127.0.0.1"
	if GameManager.join_game(ip) == OK:
		update_ui()

func _on_pilot_select_button_pressed():
	if pilot_peer_id == 0:
		rpc_request_action.rpc("SELECT_PILOT")
	elif pilot_peer_id == multiplayer.get_unique_id():
		rpc_request_action.rpc("DESELECT_PILOT")

func _on_copilot_select_button_pressed():
	if copilot_peer_id == 0:
		rpc_request_action.rpc("SELECT_COPILOT")
	elif copilot_peer_id == multiplayer.get_unique_id():
		rpc_request_action.rpc("DESELECT_COPILOT")

func _on_pilot_ready_button_pressed():
	rpc_request_action.rpc("READY_PILOT")

func _on_copilot_ready_button_pressed():
	rpc_request_action.rpc("READY_COPILOT")

@rpc("any_peer", "call_local", "reliable")
func rpc_request_action(action: String):
	if not multiplayer.is_server(): return
	
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0: sender_id = 1 # Local host case
	
	match action:
		"SELECT_PILOT":
			if pilot_peer_id == 0 and copilot_peer_id != sender_id:
				pilot_peer_id = sender_id
		"DESELECT_PILOT":
			if pilot_peer_id == sender_id:
				pilot_peer_id = 0
				pilot_ready = false
		"SELECT_COPILOT":
			if copilot_peer_id == 0 and pilot_peer_id != sender_id:
				copilot_peer_id = sender_id
		"DESELECT_COPILOT":
			if copilot_peer_id == sender_id:
				copilot_peer_id = 0
				copilot_ready = false
		"READY_PILOT":
			if pilot_peer_id == sender_id: pilot_ready = !pilot_ready
		"READY_COPILOT":
			if copilot_peer_id == sender_id: copilot_ready = !copilot_ready
	
	# Broadcast new state
	sync_state.rpc(pilot_peer_id, copilot_peer_id, pilot_ready, copilot_ready)
	check_start_conditions()

@rpc("authority", "call_local", "reliable")
func sync_state(p_id, c_id, p_ready, c_ready):
	pilot_peer_id = p_id
	copilot_peer_id = c_id
	pilot_ready = p_ready
	copilot_ready = c_ready
	update_ui()

func check_start_conditions():
	if pilot_ready and copilot_ready:
		print("SERVER: Both ready. Launching vol with Pilot:%d Copilot:%d" % [pilot_peer_id, copilot_peer_id])
		GameManager.rpc_setup_and_start.rpc(pilot_peer_id, copilot_peer_id)

func update_ui():
	var is_active = GameManager.is_network_active
	network_ui.visible = !is_active
	role_ui.visible = is_active
	
	if !is_active: return
	
	var my_id = multiplayer.get_unique_id()
	
	# --- Pilot Section ---
	if pilot_peer_id == 0:
		pilot_select_button.text = "SÉLECTIONNER"
		pilot_select_button.disabled = false
		pilot_ready_button.visible = false
	elif pilot_peer_id == my_id:
		pilot_select_button.text = "QUITTER LE RÔLE"
		pilot_select_button.disabled = false
		pilot_ready_button.visible = true
		pilot_ready_button.text = "JE SUIS PRÊT !" if pilot_ready else "ME METTRE PRÊT"
		pilot_ready_button.modulate = Color.GREEN if pilot_ready else Color.WHITE
	else:
		pilot_select_button.text = "OCCUPÉ"
		pilot_select_button.disabled = true
		pilot_ready_button.visible = false

	# --- Copilot Section ---
	if copilot_peer_id == 0:
		copilot_select_button.text = "SÉLECTIONNER"
		copilot_select_button.disabled = false
		copilot_ready_button.visible = false
	elif copilot_peer_id == my_id:
		copilot_select_button.text = "QUITTER LE RÔLE"
		copilot_select_button.disabled = false
		copilot_ready_button.visible = true
		copilot_ready_button.text = "JE SUIS PRÊT !" if copilot_ready else "ME METTRE PRÊT"
		copilot_ready_button.modulate = Color.GREEN if copilot_ready else Color.WHITE
	else:
		copilot_select_button.text = "OCCUPÉ"
		copilot_select_button.disabled = true
		copilot_ready_button.visible = false
	
	start_button.visible = false

func _on_start_button_pressed():
	pass
