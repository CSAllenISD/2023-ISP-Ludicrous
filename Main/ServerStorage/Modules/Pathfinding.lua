local PathfindingNode = require(script.PathfindingNode)

local Debug = true

local Pathfinding = {}
Pathfinding.__index = Pathfinding

function Pathfinding.new(Parent:Instance)
	local newPath = {}
	setmetatable(newPath, Pathfinding)
	newPath.Nodes = {}
	
	newPath.Main = Parent
	
	newPath.Height = 3
	newPath.MaxFall = 10
	newPath.Radius = 3
	newPath.HeightWeight = .5
	newPath.DistanceWeight = 2
	
	newPath.TestLineOfSight = true -- tests if Node is in line of sight from the main's position
	newPath.TestAvailablePath = true -- tests if the path to node is valid
	
	return newPath
end

function Pathfinding:GenerateNodeGrid(Count: number, Spacing: number)
	for i = 0, Count - 1 do
		for j = 0, Count - 1 do
			table.insert(self.Nodes, PathfindingNode.new(Vector3.new((i * Spacing) - ((Count - 1) * Spacing / 2), 0, (j * Spacing) - ((Count - 1) * Spacing / 2))))	
		end
	end
	self:Debug()
end

function Pathfinding:GetLeastWeightNode()
	if next(self.Nodes) then
		return self.Nodes[1]
	end
	return nil
end

function Pathfinding:CalculateNode(Target:Vector3, Node: PathfindingNode.PathfindingNode, blacklist: {Instance}?)
	if typeof(Node) ~= "table" then warn("PathfindingNode is not a table") return end
	if blacklist and typeof(blacklist) ~= "table" then warn("PathfindingBlacklist is not a table") return end
	
	local NodePosition = self.Main.Position + Node.Position
	
	local PathfindingParam = RaycastParams.new()
	PathfindingParam.FilterDescendantsInstances = blacklist or {}
	PathfindingParam.FilterType = Enum.RaycastFilterType.Blacklist
	PathfindingParam.RespectCanCollide = true
	
	--[[Update Node]]
	local PositionTest = workspace:Raycast(NodePosition + Vector3.new(0,self.Height,0), Vector3.new(0,-1,0) * (self.Height + self.MaxFall), PathfindingParam)
	if not PositionTest then
		Node.Weight = math.huge
	else
		local HitPos = PositionTest.Position
		
		local HeightDelta = HitPos.Y - Target.Y
		local DistanceDelta = ((HitPos - Target) * Vector3.new(1,0,1)).Magnitude
		
		local NodeWeight = math.abs(HeightDelta) * self.HeightWeight + DistanceDelta * self.DistanceWeight
		Node.Weight = NodeWeight
	end
	
	--[[TestLineofSight]]
	if self.TestLineOfSight then
		local LineOfSightTest = workspace:Raycast(self.Main.Position, Node.Position, PathfindingParam)
		if LineOfSightTest then
			Node.Weight = math.huge
		end
	end
	
	--[[TestPath]]
	if self.TestAvailablePath then
		for step = Node.Position.Magnitude - self.Radius, 0, -self.Radius do
			local pathResult = workspace:Raycast(self.Main.Position + (Node.Position.Unit * step), Vector3.new(0,-1,0) * (self.Height + self.MaxFall), PathfindingParam)
			if not pathResult then
				Node.Weight = math.huge
				return
			end
		end
	end
	
	--[[Debug]]
	if Debug and PositionTest then
		Node.DebugPart.HitDebug.Position = PositionTest.Position
	end
end

function Pathfinding:UpdateNodes(Target:Vector3)
	for _, Node: PathfindingNode.PathfindingNode in self.Nodes do
		self:CalculateNode(Target, Node, nil)
	end
	
	table.sort(self.Nodes, function(a:PathfindingNode.PathfindingNode,b:PathfindingNode.PathfindingNode)
		if a.Weight < b.Weight then return true else return false end
	end)
	
	self:Debug()
end

function Pathfinding:Debug()	
	for _, Node:PathfindingNode.PathfindingNode in self.Nodes do
		Node:Debug(self.Main.Position)
	end
	
	local lowestWeight: PathfindingNode.PathfindingNode = self.Nodes[1]
	lowestWeight.DebugPart.Color = Color3.new(1,0,0)
end

return Pathfinding
