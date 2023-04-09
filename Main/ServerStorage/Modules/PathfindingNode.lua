local RepStor = game:GetService("ReplicatedStorage")

local DebugPart = script.Debug

local Node = {}
Node.__index = Node

export type PathfindingNode = {
	Position: Vector3,
	Weight: number,
	
	DebugPart: BasePart,
	
	Remove: (self) -> (),
	Debug: (self, Offset) -> (),
}

function Node.new(Position:Vector3)
	if typeof(Position) ~= "Vector3" then error("PathfindingNodePosition is not a Vector3") end
	local newNode = {}
	setmetatable(newNode, Node)
	
	newNode.Position = Position
	newNode.Weight = math.huge
	
	newNode.DebugPart = DebugPart:Clone()
	newNode.DebugPart.Parent = workspace.Debug
	
	return newNode
end

function Node:Debug(Offset: Vector3)
	self.DebugPart.Color = Color3.new(0, 255, 0)
	self.DebugPart.Position = Offset + self.Position
	self.DebugPart.BillboardGui.Weight.Text = tostring(math.floor(self.Weight * 100) / 100)
end

function Node:Remove()
	self.DebugPart:Destroy()
	self.DebugPart = nil
	
	self.Position = nil
	self.Weight = nil
	setmetatable(self, nil)
end

return Node
