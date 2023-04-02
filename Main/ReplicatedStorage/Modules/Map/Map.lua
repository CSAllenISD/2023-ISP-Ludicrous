local RepStor = game:GetService("ReplicatedStorage")

local module = {}
module.__index = module

function module.new(InitRoom:Model, Library:string)
	local Map = {}
	Map.Library = RepStor.Assets.Map:FindFirstChild(Library):FindFirstChild("Rooms")
	if not Map.Library then error("Invalid Map Library") end
	Map.Sections = {}
	
	Map.Model = Instance.new("Model")
	Map.Model.Name = Library
	Map.Model.Parent = workspace.Map
	
	function Map:Destroy()
		for _,v in Map.Model:GetChildren() do
			v:Remove()
		end
	end
	
	local function TestIntersection(Room:Model) 
		local overlapParam = OverlapParams.new()
		overlapParam.CollisionGroup = "RoomCollision"
		overlapParam.FilterType = Enum.RaycastFilterType.Blacklist
		overlapParam.FilterDescendantsInstances = {Room}
		
		local result = workspace:GetPartBoundsInBox(Room.PrimaryPart.CFrame, Room.PrimaryPart.Size * .99, overlapParam)
		if next(result) then
			return true
		end
		return false
	end
	
	function Map:MoveRoomTo(TargetNode:Part, Node:Part, Room:Model)
		Room:PivotTo(TargetNode.CFrame)
		local AngleDifferenceY = TargetNode.CFrame.LookVector:Angle(Node.CFrame.LookVector, Vector3.new(0,1,0))
		Room:PivotTo(Room:GetPivot() * CFrame.Angles(0,-AngleDifferenceY + math.rad(180),0))
		local PositionDifference = Node.CFrame.Position - TargetNode.CFrame.Position
		Room:PivotTo(Room:GetPivot() - PositionDifference)
	end

	function Map:PlaceRoomFor(TargetRoom:Model, Room:Model)
		if Room.PrimaryPart and TargetRoom.PrimaryPart then		
			local TargetNodes = TargetRoom.PrimaryPart:GetChildren()
			local Nodes = Room.PrimaryPart:GetChildren()
			for _,TargetNode:Part in TargetNodes do
				local TargetBool = TargetNode:FindFirstChildOfClass("BoolValue")
				if not TargetNode:IsA("Part") then continue end
				
				if not TargetBool.Value then
					for _,Node:Part in Nodes do
						if not Node:IsA("Part") then continue end
						local NodeBool = Node:FindFirstChildOfClass("BoolValue")
						if not NodeBool.Value then 
							
							Map:MoveRoomTo(TargetNode, Node, Room)
							if not TestIntersection(Room) then
								TargetNode.Size = Vector3.new(3,3,3)
								Node.Size = Vector3.new(3,3,3)

								TargetBool.Value = true
								NodeBool.Value = true
								if Node:FindFirstChild("Wall") then Node:FindFirstChild("Wall"):Destroy() end
								if TargetNode:FindFirstChild("Wall") then TargetNode:FindFirstChild("Wall"):Destroy() end
								return true
							end
						end
					end
				end
			end
			return false
		else
			error("Room missing PrimaryPart bounding box")
		end
	end

	function Map:PlaceRoomRandom(TargetRoom:Model, Room:Model)
		if TargetRoom.PrimaryPart and Room.PrimaryPart then			
			local TargetNodes = TargetRoom.PrimaryPart:GetChildren()

			for count = 1, #TargetNodes do

				local Nodes = Room.PrimaryPart:GetChildren()

				local RandomTargetIndex = math.random(1, #TargetNodes)
				local TargetNode:Part = TargetNodes[RandomTargetIndex]
				if not TargetNode:IsA("Part") then error("Incorrect Room Node class") end
				local TargetBool = TargetNode:FindFirstChildOfClass("BoolValue")

				if not TargetBool.Value then 
					table.remove(TargetNodes, RandomTargetIndex)
					for count = 1, #Nodes do

						local RandomIndex = math.random(1, #Nodes)
						local Node:Part = Nodes[RandomIndex]
						if not Node:IsA("Part") then error("Incorrect Room Node class") end
						local NodeBool = Node:FindFirstChildOfClass("BoolValue")

						if not NodeBool.Value then 
							table.remove(Nodes, RandomIndex)

							Map:MoveRoomTo(TargetNode, Node, Room)

							if not TestIntersection(Room) then
								TargetNode.Size = Vector3.new(3,3,3)
								Node.Size = Vector3.new(3,3,3)

								TargetBool.Value = true
								NodeBool.Value = true
								if Node:FindFirstChild("Door") then Node:FindFirstChild("Door"):Destroy() end
								if TargetNode:FindFirstChild("Door") then TargetNode:FindFirstChild("Door"):Destroy() end
								return true
							end
						end
					end
				end
			end
			return false	
		else
			error("Room missing PrimaryPart bounding box")
		end
	end

	function Map:GetRoom(name:string?)
		if name then
			return Map.Library:FindFirstChild(name)
		else
			local Rooms = Map.Library:GetChildren()
			local Room = Rooms[math.random(1,#Rooms)]:Clone()
			Room.Parent = Map.Model
			return Room
		end 
	end

	function Map:GenerateRoom(Room:Model, Complexity:number)	
		if Complexity > 0 then		
			local newRoom = Map:GetRoom()
			local random = math.floor(math.random() + 1)
			if random == 1 then
				if Map:PlaceRoomFor(Room, newRoom) then --if room successfully generates
					table.insert(Map.Sections, newRoom)
					for count = 1, #newRoom.PrimaryPart:GetChildren() do
						Map:GenerateRoom(newRoom, Complexity - 1)
					end
				else
					newRoom:Destroy()
				end

			elseif random == 0 then
				
				if Map:PlaceRoomRandom(Room, newRoom) then --if room successfully generates
					table.insert(Map.Sections, newRoom)
					for count = 1, #newRoom.PrimaryPart:GetChildren() do
						Map:GenerateRoom(newRoom, Complexity - 1)
					end
				else
					newRoom:Destroy()
				end
			end
		end
		task.wait(.001)
	end
	
	Map.Generated = false
	function Map:GenerateMap(Complexity:number?)
		local start = os.clock()
		for count = 1, #InitRoom.PrimaryPart:GetChildren() do
			Map:GenerateRoom(InitRoom, Complexity or 5)
		end
		Map.Generated = true
		print(os.clock() - start)
	end
	return Map
end

return module
