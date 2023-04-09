local Room = require(script.Parent)

local BattleRoom = {}
BattleRoom.__index = BattleRoom
setmetatable(BattleRoom, Room)

function BattleRoom.new(Model: Model)
	local newBattleRoom = Room.new(Model)
	setmetatable(newBattleRoom, BattleRoom)
	
	if not Model:FindFirstChild("EnemyNodes") then error("BattleRoom missing EnemyNodes") end
	newBattleRoom.EnemyNodes = Model:FindFirstChild("EnemyNodes"):GetChildren()
	print(newBattleRoom.EnemyNodes)
	
	newBattleRoom.Enabled = true 
	
	newBattleRoom:Activate()	
	newBattleRoom.PlayerEntered.Event:Connect(function()
		print("Player entered BattleRoom")
		newBattleRoom:SpawnEnemies()
		newBattleRoom.Enabled = false
		newBattleRoom:CloseDoors()
	end)
	
	newBattleRoom.OnRemove.Event:Connect(function()
		newBattleRoom:Destroy()
	end)
	
	return newBattleRoom
end

function BattleRoom:SpawnEnemies()
	if self.Enabled then
		print("Spawing Enemies")
		print(self.EnemyNodes)
	end
end

function BattleRoom:Destroy()
	self.EnemyNodes = nil
	self.Enabled = nil
	
	setmetatable(self, nil)
end

return BattleRoom
