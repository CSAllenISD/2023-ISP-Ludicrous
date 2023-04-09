local RunSer = game:GetService("RunService")
local ServerStor = game:GetService("ServerStorage")
local TweenSer = game:GetService("TweenService")

local Entity = require(ServerStor.Modules.Entity)

local DoorCloseTime = 0
local DoorOpenTime = 1
local DoorOpenAmount = 10
local DoorOverExtension = 1

local Room = {}
Room.__index = Room

export type Room = {
	OnRemove: BindableEvent,
	PlayerEntered: BindableEvent,
	PlayerExited: BindableEvent,
	OnConnect: BindableEvent,
	
	CurrentPlayers: {Player},
	
	DoorsOpen: boolean,
	
	Model: Model,
	MainBound: BasePart,
	EnterTrigger: BasePart,
	ConnectionNodes: {Attachment},
	
	RemoveDoor: (self, TargetAttachment: Attachment) -> (),
	CloseDoors: (self) -> (),
	OpenDoor: (self) -> (),
	
	GetAvailableNodes: (self) -> ({Attachment}),
	
	Activate: (self) -> (),
	DeActivate: (self) -> (),
	ConnectToRoom: (self, Room, random: boolean?) -> (),
	MoveToNode: (self, TargetNode: Attachment, CurrentNode: Attachment) -> (boolean),
	CanPlace: (self) -> (boolean),
	OpenRoomNode: (self) -> ()
}

function Room.new(Model:Model)
	if typeof(Model) ~= "Instance" or not Model:IsA("Model") then error("RoomModel is not a model") end
	
	local newRoom = {}
	setmetatable(newRoom, Room)
	
	newRoom.OnRemove = Instance.new("BindableEvent")
	newRoom.PlayerEntered = Instance.new("BindableEvent")
	newRoom.PlayerExited = Instance.new("BindableEvent")
	newRoom.OnConnect = Instance.new("BindableEvent")
	
	newRoom.CurrentPlayers = {}
	
	newRoom.DoorsOpen = false
	
	newRoom.Model = Model
	newRoom.MainBound = Model.PrimaryPart
	if not newRoom.MainBound or typeof(newRoom.MainBound) ~= "Instance" or not newRoom.MainBound:IsA("BasePart") then error("RoomMainBound does not exist or is not a BasePart") end
	print(newRoom.MainBound) 
	newRoom.ConnectionNodes = Model.PrimaryPart:GetChildren()
	if not next(newRoom.ConnectionNodes) then error("Room is missing ConnectionNodes") end
	for _, node: Attachment in newRoom.ConnectionNodes do
		if typeof(node) ~= "Instance" or not node:IsA("Attachment") then error("RoomConnectionNode is not an Attachment") end
		if node:GetAttribute("Connected") == nil then error("RoomConnectionNode missing Attribute Connected") end
	end
	
	newRoom.EnterTrigger = Model:FindFirstChild("RoomEnterTrigger")
	if not newRoom.EnterTrigger then error("Room Missing Enter Trigger") end
	
	return newRoom
end

function Room:GetAvailableNodes()
	local AvailableNodes = {}
	for _, Node:Attachment in self.ConnectionNodes do
		if Node:GetAttribute("Connected") ~= nil and not Node:GetAttribute("Connected") then
			table.insert(AvailableNodes, Node)
		end
	end
	return AvailableNodes
end

function Room:ConnectToRoom(TargetRoom: Room, random: boolean?)
	if typeof(TargetRoom) ~= "table" or typeof(TargetRoom.ConnectionNodes) ~= "table" then warn("TargetRoom is not a Room") return end
	
	local CurrentAvailableNodes = self:GetAvailableNodes()
	local TargetAvailableNodes = TargetRoom:GetAvailableNodes()
	print(CurrentAvailableNodes, TargetAvailableNodes)
	local success = false
	
	if random then
		for _, _ in CurrentAvailableNodes do
			for _, _ in TargetAvailableNodes do
				local randomCurrentIndex = math.random(1, #CurrentAvailableNodes) --fetch random node from available nodes
				local CurrentAttachment = CurrentAvailableNodes[randomCurrentIndex]
				
				local randomTargetIndex = math.random(1, #TargetAvailableNodes)
				local TargetAttachment = TargetAvailableNodes[randomTargetIndex]
				
				success = self:MoveToNode(TargetAttachment, CurrentAttachment)
				if success then 
					TargetRoom.OnConnect:Fire(TargetAttachment)
					self.OnConnect:Fire(CurrentAttachment)
					break 
				end
				
				table.remove(CurrentAvailableNodes, randomCurrentIndex) --Remove tried node from available nodes
				table.remove(TargetAvailableNodes, randomTargetIndex)
			end
			if success then break end
		end	
	else
		for _, CurrentAttachment in CurrentAvailableNodes do
			for _, TargetAttachment in TargetAvailableNodes do
				
				success = self:MoveToNode(TargetAttachment, CurrentAttachment)
				if success then 
					TargetRoom.OnConnect:Fire(TargetAttachment)
					self.OnConnect:Fire(CurrentAttachment)
					break
				end
			end
			if success then break end
		end
	end
end

function Room:MoveToNode(TargetNode: Attachment, CurrentNode: Attachment) -- TargetNode is where the Room is moving to, CurrentNode is relative node
	if typeof(TargetNode) ~= "Instance" or not TargetNode:IsA("Attachment") then warn("RoomNode is not a Attachment") return end
	if typeof(CurrentNode) ~= "Instance" or not CurrentNode:IsA("Attachment") then warn("RoomNode is not a Attachment") return end

	if not table.find(self.MainBound:GetChildren(), CurrentNode) then warn("CurrentNode not part of room") return end  --Test if CurrentNode is a node in Room

	TargetNode.Visible = true
	CurrentNode.Visible = true

	self.Model:PivotTo(CFrame.new(0,0,0)) --Reset CFrame

	self.Model:PivotTo(TargetNode.WorldCFrame * CurrentNode.CFrame:Inverse() * CFrame.Angles(0,math.pi,0)) --Move Model relative to CurrentNode to Target Node (Two are in the same direction)
	self.Model:PivotTo(self.Model:GetPivot() + ((self.Model:GetPivot().Position - CurrentNode.WorldCFrame.Position) * Vector3.new(1,0,1) * 2)) --Offset Model by 2 * CurrentNode

	if not self:CanPlace({self.Model}) then
		self.Model:PivotTo(CFrame.new(0,0,0))
		return false
	end

	TargetNode:SetAttribute("Connected", true)
	CurrentNode:SetAttribute("Connected", true)
	return true
end

function Room:RemoveDoor(Attachment:Attachment)
	if typeof(Attachment) ~= "Instance" or not Attachment:IsA("Attachment") then warn("RoomAttachment is not an Attachment") return end
	
	local Opening:Model = Attachment:FindFirstChild("Opening")
	if not Opening then warn("Failed to fetch RoomAttachment Opening") return end
	Opening:Destroy()
end

function Room:CloseDoors()
	print("Attempting Door Open")
	if not self.DoorsOpen then return end
	self.DoorsOpen = false
	print(self.Model)
	for _, Attachment: Attachment in  self.MainBound:GetChildren() do --Iterating over RoomAttachmentNodes
		local Opening:Model = Attachment:FindFirstChild("Opening")
		if not Opening then continue end

		local DoorPart: BasePart
		local success, error = pcall(function()
			DoorPart = Opening.PrimaryPart
		end)
		if not success then continue end
		local Tween: Tween = TweenSer:Create(DoorPart, TweenInfo.new(DoorCloseTime), {Position = Attachment.WorldPosition})
		Tween:Play()
	end
end

function Room:OpenDoors()
	print("Attempting Door Open")
	if self.DoorsOpen then return end
	self.DoorsOpen = true
	print(self)
	for _, Attachment: Attachment in self.MainBound:GetChildren() do--Iterating over RoomAttachmentNodes
		local Opening:Model = Attachment:FindFirstChild("Opening")
		if not Opening then continue end
		
		local DoorPart: BasePart
		local success, error = pcall(function()
			DoorPart = Opening.PrimaryPart
		end)
		if not success then continue end
		local Tween:Tween = TweenSer:Create(DoorPart, TweenInfo.new(DoorOpenTime), {Position = Attachment.WorldPosition + Vector3.new(0,DoorOpenAmount + DoorOverExtension,0)})
		Tween:Play()
	end
end

function Room:Activate()
	print(self)
	if self.PlayerEnteredHandle then return end
	self.PlayerEnteredHandle = RunSer.Stepped:Connect(function(t: number, dt:number)
		local QueryParam = OverlapParams.new()
		QueryParam.CollisionGroup = "Entity"
		
		local Empty = false
		local CurrentCount = #self.CurrentPlayers
		if not next(self.CurrentPlayers) then Empty = true end
		
		self.CurrentPlayers = {}
		
		local PrimaryParts = workspace:GetPartsInPart(self.EnterTrigger, QueryParam)
		
		for _, part:BasePart in PrimaryParts do
			local EntityModel = part.Parent
			local Player: Player = Entity.GetEntityFromModel(EntityModel).Player
			if Player then
				table.insert(self.CurrentPlayers, Player)
			end
		end

		if Empty and next(self.CurrentPlayers) then self.PlayerEntered:Fire() return end
		if  CurrentCount > #self.CurrentPlayers then self.PlayerExited:Fire() return end
	end)	
end

function Room:DeActivate()
	if self.PlayerEnteredHandle then
		self.PlayerEnteredHandle:Disconnect()
	end
end

function Room:CanPlace(ignore:{Instance})
	if typeof(ignore) ~= "table" then warn("RoomPlacementTestIgnore is not a table") return end
	
	local TestParam = OverlapParams.new()
	TestParam.FilterDescendantsInstances = ignore
	TestParam.FilterType = Enum.RaycastFilterType.Blacklist
	TestParam.CollisionGroup = "RoomCollision"
	
	local intersection =	workspace:GetPartsInPart(self.MainBound, TestParam)
	if next(intersection) then
		return false
	else
		return true
	end
end

function Room:OpenRoomNode(Attachment: Attachment)
	if typeof(Attachment) ~= "Instance" or not Attachment:IsA("Attachment") then warn("RoomNode is not a Attachment") return end
	if not table.find(self.MainBound:GetChildren(), Attachment) then warn("RoomNode not part of room") return end
	
	local Opening:Model = Attachment:FindFirstChild("Opening")
	if not Opening then return end
	Opening:Destroy()
end

function Room:Remove()
	self.OnRemove:Fire()
	
	self.OnRemove:Destroy()
	self.OnRemove = nil
	self.PlayerEntered:Destroy()	
	self.PlayerEntered = nil
	self.PlayerExited:Destroy()
	self.PlayerExited = nil
	self.OnConnect:Destroy()
	self.OnConnect = nil
	
	self.CurrentPlayers = nil
	
	self.Model:Destroy()
	self.Model = nil
	self.MainBound = nil
	self.EnterTrigger = nil
	self.ConnectionNodes = nil
	
	setmetatable(self, nil)
end

return Room
