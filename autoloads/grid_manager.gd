extends Node

signal turn_changed(turn: String)

var board_text := [
	["t_b", "n_b", "b_b", "q_b", "k_b", "b_b", "n_b", "t_b"],
	["p_b", "p_b", "p_b", "p_b", "p_b", "p_b", "p_b", "p_b"],
	["",   "",   "",   "",   "",   "",   "",   ""  ],
	["",   "",   "",   "",   "",   "",   "",   ""  ],
	["",   "",   "",   "",   "",   "",   "",   ""  ],
	["",   "",   "",   "",   "",   "",   "",   ""  ],
	["p_w", "p_w", "p_w", "p_w", "p_w", "p_w", "p_w", "p_w"],
	["t_w", "n_w", "b_w", "q_w", "k_w", "b_w", "n_w", "t_w"]
]

var current_turn: String = "w"  # 'w' for white, 'b' for black
var selected_piece: Vector2i = Vector2i(-1, -1)
var valid_moves: Array = []  # Using untyped array for compatibility

const GRID_WIDTH = 8
const GRID_HEIGHT = 8
@export var grid : Dictionary

var _currently_dragging_cell: Cell
var _possible_draggeable_cell: Array

func _ready():
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell = Cell.new()
			cell.cell_pos = Vector2(x, y)
			cell.occupying_piece = board_text[y][x]
			
			# chessboard color
			if (x + y) % 2 == 0:
				cell.cell_color = Cell.CELL_COLOR.WHITE
			else:
				cell.cell_color = Cell.CELL_COLOR.BLACK
			grid[Vector2i(x, y)]=cell


#@export var cell_pos: Vector2
#@export var occupying_piece: String

func drag(p):
	var cell = grid[p.cell_pos]
	# Check if it's the correct turn
	if (p.occupying_piece.ends_with("_w") and current_turn != "w") or (p.occupying_piece.ends_with("_b") and current_turn != "b"):
		return
	
	selected_piece = p.cell_pos
	valid_moves = get_possible_moves(p.cell_pos, p.occupying_piece, grid)
	self._possible_draggeable_cell = valid_moves


func move_piece(from_pos: Vector2i, to_pos: Vector2i):
	# Check if the move is valid
	if not grid.has(from_pos) or not grid.has(to_pos):
		return false
		
	var piece = grid[from_pos].occupying_piece
	if piece == "":  # No piece to move
		return false
		
	# Check if it's the correct turn
	if (piece.ends_with("_w") and current_turn != "w") or (piece.ends_with("_b") and current_turn != "b"):
		return false
		
	# Check if the move is in valid moves
	var is_valid = false
	for move in valid_moves:
		if move == to_pos:
			is_valid = true
			break
	if not is_valid:
		return false
		
	# Perform the move
	grid[to_pos].occupying_piece = piece
	grid[from_pos].occupying_piece = ""
	
	# Switch turns
	current_turn = "b" if current_turn == "w" else "w"
	selected_piece = Vector2i(-1, -1)
	valid_moves.clear()
	
	# Emit signal for UI updates
	emit_signal("turn_changed", current_turn)
	
	return true



#var moves = get_possible_moves(Vector2i(1,6), "p_w", board_text)
#for m in moves:
	#print(m) # Vector2i positions

func get_possible_moves(pos: Vector2i, piece_type: String, grid: Dictionary) -> Array:
	var moves := []
	var x = pos.x
	var y = pos.y
	
	if piece_type == "":
		return moves
	
	# Determine piece color
	var color: String
	if piece_type.ends_with("_w"):
		color = "w"
	else:
		color = "b"
	
	# Determine piece kind
	var kind = piece_type.substr(0, piece_type.find("_"))
	
	match kind:
		"p": # Pawn
			var direction: int
			if color == "w":
				direction = -1
			else:
				direction = 1
			
			var forward_pos = Vector2i(x, y + direction)
			if grid.has(forward_pos) and grid[forward_pos].occupying_piece == "":
				moves.append(forward_pos)
			
			# Capture diagonals
			for dx in [-1, 1]:
				var diag_pos = Vector2i(x + dx, y + direction)
				if grid.has(diag_pos):
					var target_piece = grid[diag_pos].occupying_piece
					if target_piece != "" and not target_piece.ends_with("_" + color):
						moves.append(diag_pos)
			
			# Two steps from starting position
			if (color == "w" and y == 6) or (color == "b" and y == 1):
				var two_forward = Vector2i(x, y + 2 * direction)
				if grid.has(forward_pos) and grid[forward_pos].occupying_piece == "" and grid.has(two_forward) and grid[two_forward].occupying_piece == "":
					moves.append(two_forward)
		
		"r": # Rook
			for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				var nx = x
				var ny = y
				while true:
					nx += dir.x
					ny += dir.y
					var pos_check = Vector2i(nx, ny)
					if not grid.has(pos_check):
						break
					var target_piece = grid[pos_check].occupying_piece
					if target_piece == "":
						moves.append(pos_check)
					else:
						if not target_piece.ends_with("_" + color):
							moves.append(pos_check)
						break
		
		"n": # Knight
			for offset in [Vector2i(1,2), Vector2i(2,1), Vector2i(-1,2), Vector2i(-2,1), Vector2i(1,-2), Vector2i(2,-1), Vector2i(-1,-2), Vector2i(-2,-1)]:
				var nx = x + offset.x
				var ny = y + offset.y
				var pos_check = Vector2i(nx, ny)
				if grid.has(pos_check):
					var target_piece = grid[pos_check].occupying_piece
					if target_piece == "" or not target_piece.ends_with("_" + color):
						moves.append(pos_check)
		
		"b": # Bishop
			for dir in [Vector2i(1,1), Vector2i(-1,1), Vector2i(1,-1), Vector2i(-1,-1)]:
				var nx = x
				var ny = y
				while true:
					nx += dir.x
					ny += dir.y
					var pos_check = Vector2i(nx, ny)
					if not grid.has(pos_check):
						break
					var target_piece = grid[pos_check].occupying_piece
					if target_piece == "":
						moves.append(pos_check)
					else:
						if not target_piece.ends_with("_" + color):
							moves.append(pos_check)
						break
		
		"q": # Queen
			for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1), Vector2i(1,1), Vector2i(-1,1), Vector2i(1,-1), Vector2i(-1,-1)]:
				var nx = x
				var ny = y
				while true:
					nx += dir.x
					ny += dir.y
					var pos_check = Vector2i(nx, ny)
					if not grid.has(pos_check):
						break
					var target_piece = grid[pos_check].occupying_piece
					if target_piece == "":
						moves.append(pos_check)
					else:
						if not target_piece.ends_with("_" + color):
							moves.append(pos_check)
						break
		
		"k": # King
			for dx in [-1,0,1]:
				for dy in [-1,0,1]:
					if dx == 0 and dy == 0:
						continue
					var nx = x + dx
					var ny = y + dy
					var pos_check = Vector2i(nx, ny)
					if grid.has(pos_check):
						var target_piece = grid[pos_check].occupying_piece
						if target_piece == "" or not target_piece.ends_with("_" + color):
							moves.append(pos_check)
	
	return moves
