extends Node

# Game Constants
const MAX_ROUNDS = 7
const INITIAL_ALTITUDE = 6000
const ALTITUDE_STEP = 1000

# Game State Variables
var current_round: int = 1
var current_altitude: int = INITIAL_ALTITUDE
var plane_axis: int = 0 # 0 is horizontal, negative is pilot side, positive is co-pilot side
var gear_deployed: Array = [false, false, false]
var flaps_deployed: Array = [false, false, false, false]
var brakes_deployed: int = 0 # 0, 2, 4, 6

# Dice State
var pilot_dice: Array = []
var copilot_dice: Array = []

func _ready():
	print("GameManager Initialized")

func reset_game():
	current_round = 1
	current_altitude = INITIAL_ALTITUDE
	plane_axis = 0
	gear_deployed = [false, false, false]
	flaps_deployed = [false, false, false, false]
	brakes_deployed = 0
	pilot_dice = []
	copilot_dice = []
