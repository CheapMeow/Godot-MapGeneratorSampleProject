class_name RoomBase
extends Object

var connectedRooms : Array = [] # 与其直接相连的房间。
var isAccessibleFromMainRoom : bool = false # 是否能连接到主房间
var isMainRoom : bool = false # 是否主房间（最大的房间）

# 标记相对于主房间的连接性
func MarkAccessibleFromMainRoom():
	# 标记自己能够连接到主房间
	if !isAccessibleFromMainRoom:
		isAccessibleFromMainRoom = true
		# 和自己连接的房间都能连到主房间
		for connectedRoom in connectedRooms:
			connectedRoom.MarkAccessibleFromMainRoom()

# 连接房间
func ConnectRooms(roomB):
	# 传递连接标记
	if isAccessibleFromMainRoom:
		roomB.MarkAccessibleFromMainRoom()
	elif roomB.isAccessibleFromMainRoom:
		MarkAccessibleFromMainRoom()
	# 传递连接行为
	connectedRooms.append(roomB)
	roomB.connectedRooms.append(self)

# 是否连接另一个房间
func IsConnected(otherRoom):
	if connectedRooms.find(otherRoom) == -1:
		return false
	else:
		return true
