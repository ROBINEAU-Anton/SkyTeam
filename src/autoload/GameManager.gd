extends Node

signal dice_rolled
signal player_switched(new_player: String)

# --- Constants ---
const MAX_ROUNDS = 7
const MAX_AXIS = 3 # Limits are -3 and 3
const MAX_COFFEE = 3
const TRACK_LENGTH = 10 # Total distance units to airport

# --- Game State ---
var current_round: int = 1
var current_altitude: int = 7000 # Decreases by 1000 each round
var axis: int = 0 # 0 = Balanced, <0 = Pilot, >0 = Copilot
var current_distance: int = 0 # Distance traveled (0 to 10)
var coffee_tokens: int = 0
var reroll_tokens: int = 0
var current_player: String = "PILOT" # "PILOT" or "COPILOT" (Whose turn it is)
var local_role: String = "PILOT" # "PILOT" or "COPILOT" (Who this instance is)
var pilot_ready: bool = false
var copilot_ready: bool = false

# Networking
const PORT = 8910
var peer: ENetMultiplayerPeer
var is_network_active: bool = false

# Markers
var aero_blue: int = 0
var aero_orange: int = 0
var red_brakes: int = 0 # 0, 2, 4, 6

# Systems (Status)
var gear_deployed: Array[bool] = [false, false, false]
var flaps_deployed: Array[bool] = [false, false, false, false]
var radio_airplanes: Array[int] = [] # Positions of airplanes on track (relative to airport)

# Game Flow
var is_game_over: bool = false
var has_won: bool = false

# Current Turn Dice
var pilot_dice: Array = []
var copilot_dice: Array = []

func _ready():
	reset_game()

func reset_game():
	current_round = 1
	current_altitude = 7000
	axis = 0
	current_distance = 0
	coffee_tokens = 0
	reroll_tokens = 0
	aero_blue = 0
	aero_orange = 0
	red_brakes = 0
	gear_deployed = [false, false, false]
	flaps_deployed = [false, false, false, false]
	radio_airplanes = [2, 5, 8] # Example starting airplanes
	is_game_over = false
	has_won = false
	pilot_ready = false
	copilot_ready = false
	pilot_dice = []
	copilot_dice = []
	print("Game Reset")

# --- Networking ---

func host_game():
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT)
	if err != OK:
		print("Failed to host game: ", err)
		return err
	multiplayer.multiplayer_peer = peer
	is_network_active = true
	print("Game hosted on port ", PORT)
	return OK

func join_game(ip: String = "127.0.0.1"):
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, PORT)
	if err != OK:
		print("Failed to join game: ", err)
		return err
	multiplayer.multiplayer_peer = peer
	is_network_active = true
	print("Joined game at ", ip)
	return OK

@rpc("any_peer", "call_local", "reliable")
func rpc_setup_and_start(p_id: int, c_id: int):
	var my_id = multiplayer.get_unique_id()
	print("[NET] rpc_setup_and_start: MyID=%d | PilotID=%d | CopilotID=%d" % [my_id, p_id, c_id])
	
	if my_id == p_id:
		local_role = "PILOT"
		print("[NET] Assigned Role: PILOT")
	elif my_id == c_id:
		local_role = "COPILOT"
		print("[NET] Assigned Role: COPILOT")
	else:
		print("[NET] WARNING: MyID %d not found in PilotID %d or CopilotID %d" % [my_id, p_id, c_id])
		# Fallback just in case
		if my_id == 1: local_role = "PILOT"
		else: local_role = "COPILOT"
		print("[NET] Fallback Role used: ", local_role)
	
	print("[NET] Changing scene to main.tscn with role: ", local_role)
	get_tree().change_scene_to_file("res://src/scenes/main.tscn")

# --- Round Start / Readiness ---

func switch_to_player(player: String):
	if current_player != player:
		current_player = player
		player_switched.emit(current_player)
		print("Switched to player: ", current_player)

func confirm_ready(player: String):
	rpc_confirm_ready.rpc(player)

@rpc("any_peer", "call_local", "reliable")
func rpc_confirm_ready(player: String):
	if !multiplayer.is_server(): return
	
	if player == "PILOT":
		pilot_ready = true
		print("[NET-SERVER] Pilot is READY.")
	elif player == "COPILOT":
		copilot_ready = true
		print("[NET-SERVER] Copilot is READY.")
	
	if pilot_ready and copilot_ready:
		print("[NET-SERVER] Both ready. Rolling dice and starting round.")
		roll_dice() # Server rolls dice
		rpc_start_round.rpc(pilot_dice, copilot_dice)

@rpc("authority", "call_local", "reliable")
func rpc_start_round(p_dice: Array, c_dice: Array):
	pilot_ready = false
	copilot_ready = false
	pilot_dice = p_dice
	copilot_dice = c_dice
	
	dice_rolled.emit()
	print("[NET] --- ROUND %d STARTED ---" % current_round)
	print("[NET] Dice: Pilot:", pilot_dice, " Copilot:", copilot_dice)

# Local version removed to avoid confusion
func start_round():
	pass

# --- Core Actions ---

func roll_dice():
	pilot_dice.clear()
	copilot_dice.clear()
	for i in range(4):
		pilot_dice.append(randi_range(1, 6))
		copilot_dice.append(randi_range(1, 6))
	print("Dice Rolled: Pilot:", pilot_dice, " Copilot:", copilot_dice)

## 1. Axis Management
func apply_axis(pilot_die: int, copilot_die: int):
	var diff = copilot_die - pilot_die
	axis += diff
	
	print("Axis Change: Pilot(%d) Copilot(%d) -> New Axis: %d" % [pilot_die, copilot_die, axis])
	
	if abs(axis) >= MAX_AXIS:
		lose_game("Plane tilted too much! Crash.")

## 2. Engines / Speed
func apply_engines(pilot_die: int, copilot_die: int):
	var total_speed = pilot_die + copilot_die
	var advance = 0
	
	if total_speed <= aero_blue:
		advance = 0
	elif total_speed <= aero_orange:
		advance = 1
	else:
		advance = 2
	
	print("Engine Power: %d (Aero Blue: %d, Orange: %d) -> Advance: %d" % [total_speed, aero_blue, aero_orange, advance])
	
	for i in range(advance):
		current_distance += 1
		check_collisions()
		if is_game_over: return

	if current_distance >= TRACK_LENGTH and current_round < MAX_ROUNDS:
		lose_game("Overshot the airport before the last round!")

func check_collisions():
	# If an airplane is at our current distance from airport
	# Distance is 0 (start) to 10 (airport). 
	# radio_airplanes contains distance from airport (e.g. 5 means it's at track unit 5)
	# This logic depends on how track is indexed. Let's say airport is at 0.
	# We start at 10 and move towards 0.
	var airplane_pos = TRACK_LENGTH - current_distance
	if airplane_pos in radio_airplanes:
		lose_game("Collision with another aircraft!")

## 3. Individual Actions

func use_radio(die_value: int):
	# die_value determines the distance (unit) to target airplane
	var target_pos = TRACK_LENGTH - current_distance - die_value
	if target_pos in radio_airplanes:
		radio_airplanes.erase(target_pos)
		print("Radio: Airplane at distance %d removed." % die_value)
	else:
		print("Radio: No airplane at distance %d." % die_value)

func deploy_gear(_die_value: int):
	# Pilot only. Values usually fixed (e.g. 1, 2, 4)
	# For simplicity, let's assume it's sequential or specific
	# Example: 1st gear needs 1 or 2, etc. Real rules have specific spots.
	for i in range(gear_deployed.size()):
		if not gear_deployed[i]:
			gear_deployed[i] = true
			aero_blue += 1 # Moving marker to the right increases the 'slow' threshold
			print("Gear %d deployed. Aero Blue is now %d." % [i + 1, aero_blue])
			return

func deploy_flaps(_die_value: int):
	# Copilot only. Sequential.
	for i in range(flaps_deployed.size()):
		if not flaps_deployed[i]:
			flaps_deployed[i] = true
			aero_orange += 1 # Moving marker increases 'fast' threshold
			print("Flaps %d deployed. Aero Orange is now %d." % [i + 1, aero_orange])
			return

func apply_brakes(die_value: int):
	# Pilot only. Sequential 2, 4, 6
	if die_value > red_brakes:
		red_brakes = die_value
		print("Brakes set to %d." % red_brakes)

## 4. Support Mechanics

func spend_coffee(die_index: int, amount: int, is_pilot: bool):
	if coffee_tokens > 0:
		coffee_tokens -= 1
		var dice_ref = pilot_dice if is_pilot else copilot_dice
		dice_ref[die_index] = clamp(dice_ref[die_index] + amount, 1, 6)
		print("Coffee used! New die value: %d" % dice_ref[die_index])

func gain_coffee():
	if coffee_tokens < MAX_COFFEE:
		coffee_tokens += 1
		print("Coffee gained. Total: %d" % coffee_tokens)

func use_reroll():
	if reroll_tokens > 0:
		reroll_tokens -= 1
		print("Reroll used!")
		return true
	return false

# --- End Game Logic ---

func end_round():
	current_round += 1
	current_altitude -= 1000
	if current_round > MAX_ROUNDS:
		check_victory_conditions()
	else:
		print("Round %d starting. Altitude: %d" % [current_round, current_altitude])

func lose_game(reason: String):
	is_game_over = true
	has_won = false
	print("GAME OVER: " + reason)

func check_victory_conditions():
	if is_game_over: return
	
	var success = true
	
	if axis != 0:
		print("Fail: Axis not horizontal.")
		success = false
	
	if not gear_deployed.all(func(g): return g):
		print("Fail: Gear not fully deployed.")
		success = false
		
	if not flaps_deployed.all(func(f): return f):
		print("Fail: Flaps not fully deployed.")
		success = false
		
	if radio_airplanes.size() > 0:
		print("Fail: Airplanes remaining on track.")
		success = false
		
	# Final track position must be the airport (TRACK_LENGTH)
	if current_distance < TRACK_LENGTH:
		print("Fail: Haven't reached the airport.")
		success = false
		
	# Speed check vs Brakes
	# The sum of dice in the final round must be less than red_brakes
	# For simplicity, we check total_speed of final engine call here if needed
	# But rules say "Vitesse totale < valeur freins"
	
	if success:
		has_won = true
		is_game_over = true
		print("VICTORY! Smooth landing.")
	else:
		lose_game("Landing conditions not met at the end of round 7.")
