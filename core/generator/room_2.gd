extends RoomBase

# 房间的中心（在 map 中的坐标，不是世界坐标）
var center : Vector2i
# 房间半长（不包括中心）
var halfSize : Vector2i

func _init(ct, hs):
	center = ct
	halfSize = hs
