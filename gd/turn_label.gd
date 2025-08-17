extends Label

func _ready():
	# Connect to the turn changed signal if it exists
	if GridManager.has_signal("turn_changed"):
		GridManager.connect("turn_changed", Callable(self, "_on_turn_changed"))

func _on_turn_changed(turn: String):
	text = "White's turn" if turn == "w" else "Black's turn"
