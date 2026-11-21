class_name ArenaFraming
extends RefCounted


static func focus_between(
	player: Vector2, boss_top: Vector2, screen: Vector2, top_margin: float
) -> Vector2:
	var x: float = (player.x + boss_top.x) * 0.5
	var y: float = boss_top.y - top_margin + screen.y * 0.5
	return Vector2(x, y).round()


static func high_bottom(boss_top_y: float, top_margin: float, screen_height: float) -> float:
	return boss_top_y - top_margin + screen_height


static func limit_bottom(feet_y: float, split_y: float, high: float, low: float) -> float:
	return low if feet_y > split_y else high


static func top_on_screen(world_y: float, limit_bottom_y: float, screen_height: float) -> float:
	return world_y - (limit_bottom_y - screen_height)


static func clamp_center(center: Vector2, limits: Rect2, screen: Vector2) -> Vector2:
	var half: Vector2 = screen * 0.5
	var result: Vector2 = center
	if limits.size.x >= screen.x:
		result.x = clampf(center.x, limits.position.x + half.x, limits.end.x - half.x)
	if limits.size.y >= screen.y:
		result.y = clampf(center.y, limits.position.y + half.y, limits.end.y - half.y)
	return result
