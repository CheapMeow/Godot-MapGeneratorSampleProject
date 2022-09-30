extends MapGeneratorBase

const Room = preload("room_1.gd")

# 随机填充百分比，越大洞越小
@export_range(0.0,1.0) var fillThreshold : float = 0.55

# 平滑程度（次数）
@export_range(0,20) var smoothLevel : int = 4

# 清除小墙体的阈值
@export var wallThresholdSize : int = 50
# 清除小孔的的阈值
@export var roomThresholdSize : int = 50

# 通道（房间与房间直接）宽度
@export var passageWidth : int = 4

@export var borderSize : int = 1

# 地图集，Empty为空洞，Wall为实体墙
var map : Array

func _ready():
	generate_map()
	set_gridmap_by_empty()

func _input(event):
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				clear_map()
				generate_map()
				set_gridmap_by_empty()

# 清理地图
func clear_map():
	map.clear()
	roomList.clear()
	clear()
	
# 生成随机地图
func generate_map():
	for x in range(width):
		map.append([])
		for y in range(height):
			map[x].append(GEnum.TileType.Empty)
	random_fill_map()

	for i in range(smoothLevel):
		smooth_map()

	# 清除小洞，小墙
	eliminate_small_hole_and_wall()

	# 连接各个幸存房间
	connect_all_rooms_to_mainroom()

# 设置 3d 瓦片地图
func set_gridmap_by_empty():
	for x in range(width):
		for y in range(height):
			if map[x][y] == GEnum.TileType.Empty:
				set_cell_item(Vector3i(x,0,y),0,0)
	
# 随机填充地图
func random_fill_map():
	if useRandomSeed:
		mapSeed = Time.get_datetime_string_from_system()
	seed(mapSeed.hash())

	for x in range(width):
		for y in range(height):
			if x == 0 || x == width - 1 || y == 0 || y == height - 1:
				map[x][y] = GEnum.TileType.Wall
			else:
				map[x][y] = GEnum.TileType.Wall if randf_range(0,1) < fillThreshold else GEnum.TileType.Empty

# 平滑地图
func smooth_map():
	for x in range(width):
		for y in range(height):
			var neighbourWallTiles = get_surround_wall_count(x, y)
			if neighbourWallTiles > 4: # 周围大于四个墙，那自己也是墙
				map[x][y] = GEnum.TileType.Wall
			elif neighbourWallTiles < 4: #周围大于四个为空，那自己也为空
				map[x][y] = GEnum.TileType.Empty
			# 还有如果四四开，那就保持不变。

# 获取该点周围 8 个点为实体墙（map[x][y] == 1）的个数
func get_surround_wall_count(x, y):
	var wallCount = 0
	for nx in [x-1, x+1]:
		for ny in [y-1, y+1]:
			if nx >= 0 && nx < width && ny >= 0 && ny < height:
				wallCount += 1 if map[x][y] == GEnum.TileType.Wall else 0
			else:
				wallCount += 1
	return wallCount

# 加工地图，清除小洞，小墙，连接房间。
func eliminate_small_hole_and_wall():
	# 获取最大房间的索引
	var currentIndex : int = 0
	var maxIndex : int = 0
	var maxSize : int = 0
	
	# 获取墙区域
	var wallRegions = get_regions(GEnum.TileType.Wall)
	for wallRegion in wallRegions:
		if wallRegion.size() < wallThresholdSize:
			for tile in wallRegion:
				map[tile.x][tile.y] = GEnum.TileType.Empty # 把小于阈值的都铲掉
				
	# 获取空洞区域
	var roomRegions = get_regions(GEnum.TileType.Empty)
	for roomRegion in roomRegions:
		if roomRegion.size() < roomThresholdSize:
			for tile in roomRegion:
				map[tile.x][tile.y] = GEnum.TileType.Wall # 把小于阈值的都填充
		else:
			var sRoom = Room.new(roomRegion, map)
			roomList.append(sRoom) # 添加到幸存房间列表里
			if maxSize < roomRegion.size():
				maxSize = roomRegion.size()
				maxIndex = currentIndex # 找出最大房间的索引
			currentIndex += 1

	if roomList.size() == 0:
		print_debug("No Survived Rooms Here!!")
	else:
		roomList[maxIndex].isMainRoom = true # 最大房间就是主房间
		roomList[maxIndex].isAccessibleFromMainRoom = true

# 获取区域
func get_regions(tileType):
	var regions : Array
	var mapFlags = BitMap.new()
	mapFlags.create(Vector2(width, height))
	
	for x in range(width):
		for y in range(height):
			if mapFlags.get_bit(x, y) == false && map[x][y] == tileType:
				regions.append(get_region_tiles(x, y, tileType, mapFlags))
	
	return regions

# 从这个点开始获取区域，广度优先算法
func get_region_tiles(startX, startY, tileType, mapFlags):
	var tiles : Array
	var quene1 : Array
	var quene2 : Array
	quene1.append(Vector2i(startX, startY))
	mapFlags.set_bit(startX, startY, true)

	while quene1.size() > 0:
		var tile = quene1.pop_back()
		tiles.append(tile)

		# 遍历上下左右四格
		for i in range(4):
			var x = tile.x + GEnum.Vector2_Dir[i].x;
			var y = tile.y + GEnum.Vector2_Dir[i].y;
			if is_in_map_range(x, y) && mapFlags.get_bit(x, y) == false && map[x][y] == tileType:
				mapFlags.set_bit(x, y, true)
				quene2.append(Vector2i(x, y))

		if quene1.size() == 0:
			quene1 = quene2
			quene2 = Array()

	return tiles

# 把所有房间都连接到主房间
func connect_all_rooms_to_mainroom():
	for room in roomList:
		connect_to_closest_room(room)

	var count = 0
	for room in roomList:
		if room.isAccessibleFromMainRoom:
			count += 1
	if count != roomList.size():
		connect_all_rooms_to_mainroom()
	
# 连接本房间与距离自己最近的一个与自己尚未连接的房间
# 可能找不到满足条件的待连接房间
func connect_to_closest_room(roomA):
	var bestDistance : int = 9223372036854775807
	var bestTileA : Vector2i
	var bestTileB : Vector2i
	var bestRoomB
	
	var hasChecked = false
	
	for roomB in roomList:
		if roomA == roomB || roomA.IsConnected(roomB):
			continue
		
		for tileA in roomA.edgeTiles:
			for tileB in roomB.edgeTiles:
				var distanceBetweenRooms = (tileA - tileB).length_squared()
				# 如果找到更近的（相对roomA）房间，更新最短路径。
				if distanceBetweenRooms < bestDistance:
					bestDistance = distanceBetweenRooms
					bestTileA = tileA
					bestTileB = tileB
					bestRoomB = roomB

	if bestRoomB != null:
		create_passage(roomA, bestRoomB, bestTileA, bestTileB)

# 创建两个房间的通道
func create_passage(roomA, roomB, tileA, tileB):
	roomA.ConnectRooms(roomB)
	var line = get_line(tileA, tileB)
	for coord in line:
		draw_circle(coord, passageWidth)

# 以点c为原点，r为半径，画圈（拆墙）
func draw_circle(c, r):
	for x in range(-r, r):
		for y in range(-r, r):
			if x * x + y * y <= r * r:
				var drawX = c.x + x
				var drawY = c.y + y
				if is_in_map_range(drawX, drawY):
					map[drawX][drawY] = GEnum.TileType.Empty
