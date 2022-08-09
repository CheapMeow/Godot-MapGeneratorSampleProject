# Godot-MapGeneratorSampleProject

![icon](https://user-images.githubusercontent.com/88229072/183573519-d90b3999-142a-4fc9-a8f3-fe6c00517469.png)

![不规则地图](https://user-images.githubusercontent.com/88229072/183570548-0015167d-6454-47cb-a162-95222f493504.gif)
![规则地图](https://user-images.githubusercontent.com/88229072/183570549-346005f5-7550-41c3-8602-06015a0fdfe5.gif)

## 二维随机地图生成方法

1.新建一个枚举类型的二维数组 `map`，每个元素代表着每一个格子，枚举内容代表格子的种类，例如空地、墙（六边形网格地图可以变形为四边形网格地图）

2.自定义随机填充算法初始化 `map`

3.自定义平滑算法处理 `map`

例如：遍历 `map` 每个元素，计算其周围 8 个元素为墙的个数，等于 4 个时保持不变，大于一半则自己也变成墙，反之为空地

4.清除小的墙体、空地

`map` 中一些位置连续的，同一枚举类型的元素可以视为一个整体，它不是墙就是空地，用 `List<Vector2>` 表示，通过广度优先找出
    
先删掉小墙体，这样有些房间就会变大，找小空洞时，所有房间的大小确定不变
    
再删掉小空地，并且把没删掉的作为房间存起来
    
最后把房间最大的作为主房间
    
5.房间连接
    
遍历所有房间，对其中每一个房间，寻找可能存在的，距离自己最近的，与自己尚未连接的房间
    
连接房间时，进行两项操作：
    
(1) 连接时遍历两个房间的边界上的节点，找到两个房间之间距离最近的一对边节点，由直线生成算法获得直线上各点。遍历各点，在以给定的通道宽度为半径，列表元素为圆心的，圆内的所有地图节点，都置为空地
    
(2) 房间 a 如果可以到达主房间，那么与之相连的所有房间都可以连接到主房间
重复遍历若干次，直至所有房间都可以到达主房间

## 2D Random Map Generation Method

1.Create a new two-dimensional array `map` of enumeration type, each element represents each grid, and the enumeration content represents the type of grid, such as open space, wall (the hexagonal grid map can be transformed into a quadrilateral grid map)

2.Customize the random filling algorithm to initialize the `map`

3.Custom smoothing algorithm to process `map`

For example: traverse each element of the `map`, and calculate the number of walls around the 8 elements. If it is equal to 4, it will remain unchanged. If it is greater than half, it will become a wall, else it will be space.

4.Clear small walls and spaces

Some elements of the same enumeration type in the map that are continuous in position can be regarded as a whole. It is either a hand of walls or spaces. It is represented by `List<Vector2i>` and is found by BFS.
    
Delete the small walls first, so that some rooms will become larger. When looking for small holes, the size of all rooms will be fixed.
    
Then delete the small space, and save the ones that are not deleted as the room
    
Finally, use the largest room as the main room
    
5.Room connection
    
Traverse all the rooms, and for each of them, look for the possible room that is closest to you and has not yet been connected to yourself
    
When connecting rooms, do two things:
    
(1) Traverse the nodes on the boundary of the two rooms, find a pair of edge nodes with the closest distance between the two rooms, and obtain each point on the line by the line generation algorithm. Traverse each point in the line as center, with the given passage width as the radius, all map nodes in the circle are set as empty spaces
    
(2) If room a can reach main room, all rooms connected to a can be connected to the main room

Repeat the traversal until all rooms can reach the main room
