extends PanelContainer

@onready var label = $Label

var die_value: int = 0:
	set(value):
		die_value = value
		if label:
			label.text = str(die_value)

func set_role(is_pilot: bool):
	if is_pilot:
		modulate = Color("#3498db") # Pilot Blue
	else:
		modulate = Color("#e67e22") # Copilot Orange

func _ready():
	label.text = str(die_value)
