class_name MapGeneratorBase
extends GridMap

# 地图的宽度
@export var width : int = 64
# 地图的高度
@export var height : int = 64

# 地图种子
@export var mapSeed : String
# 是否使用随机种子
@export var useRandomSeed : bool = true

# 房间列表
var roomList : Array

# Bresenham 直线生成算法
# 对于直线 y = k*x (0<k<1) 
# 每在 x 方向上走一步，直线在 y 方向上都增加一个 k 的距离
# 要确定 y 方向上取直线上方的格还是直线下方的格，即
# d += k > 0.5 d 为累加器，初值为 0，取得直线上方一格后需减 1
# 两边同乘 2*dx 其中 dx 为起点到终点的在 x 方向上的距离，得
# 2*dx*d += 2*dy > dx 其中 dy 为起点到终点的在 x 方向上的距离
func get_line(from, to):
	var line : Array

	var x = from.x
	var y = from.y

	var dx = to.x - from.x
	var dy = to.y - from.y

	var inverted = false
	var step = sign(dx)
	var gradientStep = sign(dy)

	var longest = abs(dx)
	var shortest = abs(dy)

	if longest < shortest:
		inverted = true
		longest = abs(dy)
		shortest = abs(dx)

		step = sign(dy)
		gradientStep = sign(dx)

	var acc = 0
	for i in range(longest):
		line.append(Vector2i(x, y))

		if inverted:
			y += step
		else:
			x += step

		acc += 2*shortest # 梯度每次增长为短边的长度。
		if acc >= longest:
			if inverted:
				x += gradientStep
			else:
				y += gradientStep
			acc -= 2*longest

	return line

# 判断坐标是否在地图里，不管墙还是洞
func is_in_map_range(x, y):
	return x >= 0 && x < width && y >= 0 && y < height
