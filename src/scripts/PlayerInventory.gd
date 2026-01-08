extends CanvasLayer

@onready var h_box = $MarginContainer/HBoxContainer
@export var is_pilot: bool = true

const DICE_SLOT = preload("res://src/scenes/DiceSlot.tscn")

func _ready():
	GameManager.dice_rolled.connect(update_inventory)
	update_inventory()

func update_inventory():
	print("[UI] Mise à jour de l'inventaire pour: ", "PILOT" if is_pilot else "COPILOT")
	# Clear existing
	for child in h_box.get_children():
		child.queue_free()
	
	var dice = GameManager.pilot_dice if is_pilot else GameManager.copilot_dice
	
	for value in dice:
		var slot = DICE_SLOT.instantiate()
		h_box.add_child(slot)
		slot.die_value = value
		slot.set_role(is_pilot)

func _process(_delta):
	var active = (GameManager.current_player == "PILOT" and is_pilot) or (GameManager.current_player == "COPILOT" and not is_pilot)
	visible = active
