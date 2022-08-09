extends MapGeneratorBase

const Room = preload("room_2.gd")

# 各房间中点之间的距离（不包括两端点）（钳制到最大允许奇数）
@export var roomCentersSpace : Vector2i = Vector2i(21, 21)

# 最小房间尺寸（钳制到最大允许奇数）
@export var minRoomSize : Vector2i = Vector2i(7, 7)
# 最大房间尺寸（钳制到最大允许奇数）
@export var maxRoomSize : Vector2i = Vector2i(19, 19)

# 最小房间数目
@export var minRoomCount : int = 4
# 最大房间数目（钳制到地图限制）
@export var maxRoomCount : int = 10

# 通道（房间与房间直接）宽度
@export var passageWidth : int = 3

# 地图集的横向大小
var mapSizeX : int
# 地图集的纵向大小
var mapSizeY : int
# 地图集，Empty为空洞，Wall为实体墙
var map : Array

# Called when the node enters the scene tree for the first time.
func _ready():
	generate_map()
	draw_rooms()
	connect_all_rooms_to_mainroom()

func _input(event):
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				clear_map()
				generate_map()
				draw_rooms()
				connect_all_rooms_to_mainroom()

# 清理地图
func clear_map():
	map.clear()
	roomList.clear()
	clear()
	
# 生成随机地图
func generate_map():
	mapSizeX = floor(width/roomCentersSpace.x)
	mapSizeY = floor(height/roomCentersSpace.y)
	for x in range(mapSizeX):
		map.append([])
		for y in range(mapSizeY):
			map[x].append(GEnum.TileType.Empty)
	random_fill_map()

# 随机填充地图
func random_fill_map():
	if useRandomSeed:
		mapSeed = Time.get_datetime_string_from_system()
	seed(mapSeed.hash())
	
	var roomCount = randi_range(minRoomCount, maxRoomCount)
	roomCount = mini(roomCount, mapSizeX*mapSizeY)
	var expandSize = (maxRoomSize - minRoomSize)/2
	
	var center = Vector2i(floor(mapSizeX/2), floor(mapSizeY/2))
	var halfSize : Vector2i
	var room
	
	var acc : int = 0
	
	while acc < roomCount:
		# 如果不是第一个房间，那么房间的中心需要随机确定
		if acc != 0:
			room = roomList[randi_range(0, roomList.size()-1)]
			center = room.center + GEnum.Vector2_Dir[randi_range(0,3)]
			# 越界则重找
			if center.x < 0 || center.x >= mapSizeX || center.y < 0 || center.y >= mapSizeY:
				continue
			# 该位置已有房间，则重找
			if map[center.x][center.y] == GEnum.TileType.Wall:
				continue
				
		# 找到一个可用的房间
		acc += 1
		map[center.x][center.y] = GEnum.TileType.Wall
		
		# 随机扩大
		halfSize = (minRoomSize-Vector2i.ONE)/2 + Vector2i(randi_range(0, expandSize.x), randi_range(0, expandSize.y))
		room = Room.new(center, halfSize)
		# 取第一个房间为主房间
		if acc == 1:
			room.isMainRoom = true
			room.MarkAccessibleFromMainRoom()
		roomList.append(room)
	
# 绘制房间
func draw_rooms():
	var center : Vector2i
	for room in roomList:
		# 转化到世界坐标
		center = room.center * roomCentersSpace
		for x in range(center.x-room.halfSize.x, center.x+room.halfSize.x+1):
			for y in range(center.y-room.halfSize.y, center.y+room.halfSize.y+1):
				set_cell_item(Vector3i(x,0,y),0,0)
	
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
	# 只找上下左右一格内的房间
	var center = roomA.center + GEnum.Vector2_Dir[randi_range(0,3)]
	# 越界则放弃
	if center.x < 0 || center.x >= mapSizeX || center.y < 0 || center.y >= mapSizeY:
		return
	# 该位置没有房间，则放弃
	if map[center.x][center.y] == GEnum.TileType.Empty:
		return
	
	for roomB in roomList:
		if roomB.center == center:
			if !roomA.IsConnected(roomB):
				create_passage(roomA, roomB)
			break

# 创建两个房间的通道
func create_passage(roomA, roomB):
	roomA.ConnectRooms(roomB)
	# 转化到世界坐标
	var centerA = roomA.center * roomCentersSpace
	var centerB = roomB.center * roomCentersSpace
	# 方向 1 代表 横向，0 代表 纵向
	var dir
	if (roomB.center - roomA.center).abs().x != 0:
		dir = 1
	else:
		dir = 0
	# 通道半宽
	var halfWidth = floor(passageWidth/2)
	# 两点连线上各点
	var line = get_line(centerA, centerB)
	for dot in line:
		if dir == 1:
			for y in range(dot.y-halfWidth, dot.y+halfWidth+1):
				set_cell_item(Vector3i(dot.x,0,y),0,0)
		else:
			for x in range(dot.x-halfWidth, dot.x+halfWidth+1):
				set_cell_item(Vector3i(x,0,dot.y),0,0)
