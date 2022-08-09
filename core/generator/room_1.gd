extends RoomBase

var tiles : Array = [] # 所有坐标
var edgeTiles : Array = [] # 靠边的坐标

func _init(roomTiles, map):
	tiles = roomTiles
	UpdateEdgeTiles(map)

# 更新房间边缘瓦片集
func UpdateEdgeTiles(map):
	edgeTiles.clear()
	# 遍历上下左右四格，判断是否有墙
	for tile in tiles:
		for i in range(4):
			var x = tile.x + GEnum.Vector2_Dir[i].x
			var y = tile.y + GEnum.Vector2_Dir[i].y
			if map[x][y] == GEnum.TileType.Wall && !edgeTiles.has(tile):
				edgeTiles.append(tile)
