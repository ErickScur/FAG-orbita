class_name LevelParser
extends RefCounted

const SOLID: String = "#"
const ONE_WAY: String = "="
const EMPTY: String = " "
const SPAWN: String = "P"
const WINDOW: String = "W"
const ATLAS_COLUMNS: int = 8
const MASK_UP: int = 1
const MASK_RIGHT: int = 2
const MASK_DOWN: int = 4
const MASK_LEFT: int = 8
const ANCHOR_FEET: StringName = &"feet"
const ANCHOR_CENTER: StringName = &"center"
const TILE_CHARS: String = "#= PW"


static func parse(text: String, legend_chars: String) -> Dictionary:
	var errors: PackedStringArray = []
	var warnings: PackedStringArray = []
	var lines: PackedStringArray = _split_lines(text)
	var width: int = _longest_line(lines)
	var height: int = lines.size()
	var solids: Dictionary = {}
	var one_ways: Array[Vector2i] = []
	var windows: Array[Vector2i] = []
	var entities: Array[Dictionary] = []
	var spawns: Array[Vector2i] = []
	for row: int in range(height):
		var line: String = lines[row]
		if line.length() < width:
			warnings.append(
				"linha %d: %d colunas, preenchida até %d" % [row + 1, line.length(), width]
			)
		for column: int in range(width):
			var symbol: String = line.substr(column, 1) if column < line.length() else EMPTY
			var cell := Vector2i(column, row)
			match symbol:
				SOLID:
					solids[cell] = true
				ONE_WAY:
					one_ways.append(cell)
				WINDOW:
					windows.append(cell)
				SPAWN:
					spawns.append(cell)
				EMPTY:
					continue
				_:
					if legend_chars.contains(symbol):
						entities.append({"symbol": symbol, "cell": cell})
					else:
						errors.append(
							"linha %d, coluna %d: caractere '%s' desconhecido"
							% [row + 1, column + 1, symbol]
						)
	if spawns.is_empty():
		errors.append("fase sem spawn: nenhum caractere '%s' encontrado" % SPAWN)
	elif spawns.size() > 1:
		errors.append("fase com %d spawns '%s': deve haver exatamente 1" % [spawns.size(), SPAWN])
	return {
		"width": width,
		"height": height,
		"solids": solids,
		"one_ways": one_ways,
		"windows": windows,
		"entities": entities,
		"spawn": spawns[0] if spawns.size() == 1 else Vector2i.ZERO,
		"errors": errors,
		"warnings": warnings,
	}


static func neighbor_mask(solids: Dictionary, cell: Vector2i, width: int, height: int) -> int:
	var mask: int = 0
	if _is_solid(solids, cell + Vector2i.UP, width, height):
		mask |= MASK_UP
	if _is_solid(solids, cell + Vector2i.RIGHT, width, height):
		mask |= MASK_RIGHT
	if _is_solid(solids, cell + Vector2i.DOWN, width, height):
		mask |= MASK_DOWN
	if _is_solid(solids, cell + Vector2i.LEFT, width, height):
		mask |= MASK_LEFT
	return mask


static func atlas_coords_for_mask(mask: int) -> Vector2i:
	var clamped: int = clampi(mask, 0, 15)
	return Vector2i(clamped % ATLAS_COLUMNS, clamped / ATLAS_COLUMNS)


static func cell_to_position(cell: Vector2i, anchor: StringName, tile_size: int) -> Vector2:
	var half: float = tile_size * 0.5
	var x: float = cell.x * tile_size + half
	if anchor == ANCHOR_FEET:
		return Vector2(x, float((cell.y + 1) * tile_size))
	return Vector2(x, cell.y * tile_size + half)


static func cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


static func key_to_cell(key: String) -> Vector2i:
	var parts: PackedStringArray = key.split(",")
	if parts.size() != 2:
		return Vector2i(-1, -1)
	return Vector2i(int(parts[0].strip_edges()), int(parts[1].strip_edges()))


static func _is_solid(solids: Dictionary, cell: Vector2i, width: int, height: int) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return true
	return solids.has(cell)


static func _split_lines(text: String) -> PackedStringArray:
	var normalized: String = text.replace("\r\n", "\n").replace("\r", "\n")
	var lines: PackedStringArray = normalized.split("\n")
	while lines.size() > 0 and lines[lines.size() - 1].is_empty():
		lines.remove_at(lines.size() - 1)
	return lines


static func _longest_line(lines: PackedStringArray) -> int:
	var longest: int = 0
	for line: String in lines:
		longest = maxi(longest, line.length())
	return longest
