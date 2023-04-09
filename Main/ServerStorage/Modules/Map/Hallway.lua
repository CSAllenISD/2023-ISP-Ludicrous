local Room = require(script.Parent)

local Hallway = {}
Hallway.__index = Hallway
setmetatable(Hallway, Room)

function Hallway.new(Model: Model)
	local newHallway = Room.new(Model)
	setmetatable(newHallway, Hallway)
	
	newHallway.OnConnect.Event:Connect(function(Attachment: Attachment)
		local Opening = Attachment:FindFirstChild("Opening")
		if not Opening then return end
		Opening:Destroy()
		print("destroyed Opening")
	end)	
	
	return newHallway
end


return Hallway
