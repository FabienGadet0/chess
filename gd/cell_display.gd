extends TextureRect

#@export var cell_type: CELL_TYPE
var original_texture: Texture2D
var is_drag_source: bool = false   # mark this cell when dragging
@export var cell_pos: Vector2i
@export var occupying_piece: String
var highlight_color = Color(0.5, 1, 0.5, 0.5)  # Light green highlight for valid moves
var is_highlighted: bool = false

func _ready():
	update_texture()

func update_texture():
	if occupying_piece != "":
		# Build the path dynamically
		var path = "res://assets/Simple_Chess_by_skyel/%s.png" % occupying_piece
		# Load the texture
		var tex: Texture2D = load(path)
		# Assign it
		self.texture = tex
	else:
		self.texture = null

# trigger when click and drag
func _get_drag_data(at_position: Vector2) -> Variant:
	if occupying_piece == "" or (occupying_piece.ends_with("_w") and GridManager.current_turn != "w") or (occupying_piece.ends_with("_b") and GridManager.current_turn != "b"):
		return null  # nothing to drag or wrong turn
		
	# Store the original position and texture
	original_texture = texture
	is_drag_source = true
	
	# Get valid moves
	GridManager.drag(self)
	if GridManager.valid_moves.is_empty():
		is_drag_source = false
		return null  # no valid moves for this piece
		
	# Queue redraw to show valid moves
	queue_redraw()

	# create a container for preview
	var preview_container := Control.new()
	preview_container.size = size

	# create the actual texture
	var preview_texture := TextureRect.new()
	preview_texture.texture = texture
	preview_texture.size = size
	preview_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# shift the texture inside the container so cursor is at the click point
	preview_texture.position = -at_position
	preview_container.add_child(preview_texture)

	# set the drag preview
	set_drag_preview(preview_container)

	original_texture = texture
	is_drag_source = true

	texture = null
	return self

# trigger when hover with a dragged item
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Only allow drop if it's a valid move and not the same cell
	for move in GridManager.valid_moves:
		if move == cell_pos and data != self:
			return true
	return false

# trigger when you drop the dragged item
func _drop_data(at_position: Vector2, data: Variant) -> void:
	# Move the piece in the grid
	if GridManager.move_piece(data.cell_pos, cell_pos):
		# Update the texture of the target cell
		update_texture()
		# Clear the source cell
		if data != self:
			data.occupying_piece = ""
			data.texture = null
			
		# Clear highlights
		GridManager.valid_moves.clear()
		queue_redraw()

# notification when drag ends
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and is_drag_source:
		if not is_drag_successful():
			# only the drag source restores itself
			texture = original_texture
		is_drag_source = false
		GridManager.valid_moves.clear()
		queue_redraw()

# Draw valid move indicators
func _draw():
	for move in GridManager.valid_moves:
		if move == cell_pos:
			draw_rect(Rect2(Vector2.ZERO, size), highlight_color, false, 2.0)
			var center = size / 2
			draw_circle(center, min(size.x, size.y) * 0.2, highlight_color)
			break
