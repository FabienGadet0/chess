extends Control
@onready var grid = $CanvasLayer/VBoxContainer/CenterContainer/grid
@onready var cell_display_scene = preload("res://tscn/cell_display.tscn")
@onready var turn_label = $CanvasLayer/VBoxContainer/TurnLabel

func _ready():
	# Initialize the board
	GridManager.turn_changed.connect(_on_turn_changed)
	update_board()
	update_turn_display()

func _on_turn_changed(_turn: String):
	update_board()
	update_turn_display()

func update_board():
	# Clear existing pieces
	for child in grid.get_children():
		child.queue_free()
	
	# Create new pieces
	for y in range(8):
		for x in range(8):
			var pos = Vector2i(x, y)
			if GridManager.grid.has(pos):
				var cell = GridManager.grid[pos]
				var cell_display = cell_display_scene.instantiate()
				cell_display.occupying_piece = str(cell.occupying_piece)
				cell_display.cell_pos = cell.cell_pos
				grid.add_child(cell_display)

func update_turn_display():
	var turn_text = "White's turn" if GridManager.current_turn == "w" else "Black's turn"
	turn_label.text = turn_text
