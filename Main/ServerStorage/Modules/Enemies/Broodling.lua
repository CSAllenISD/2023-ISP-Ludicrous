local ServerStor = game:GetService("ServerStorage")
local RunSer = game:GetService("RunService")

local Entity = require(ServerStor.Modules.Entity)
local Pathfinding = require(ServerStor.Modules.Pathfinding)
local HealthValue = require(ServerStor.Modules.Entity.HealthValue)

local MaxDetectionRange = 150

local AttackRange = 10
local AttackDamage = 20
local AttackCooldown = .5 
	
local random = Random.new()

local Broodling = {}
Broodling.__index = Broodling
setmetatable(Broodling, Entity)

function Broodling.new(Location: CFrame)
	local newBroodling = Entity.new("Broodling")
	setmetatable(newBroodling, Broodling)
	newBroodling.Model:PivotTo(Location)
		
	newBroodling:SetHealth({HealthValue.new("Health", 35, 35)})
	newBroodling:AddResistance("Fire", 0, 2)
	
	
	newBroodling.MaxWalkSpeed:SetValue(10)
	newBroodling.WalkForce:SetValue(3000)
	newBroodling.DragCoefficient = 30
	
	newBroodling:CalculateMovementInServer()
	
	newBroodling.Pathfinding = Pathfinding.new()
	--newBroodling.Pathfinding:GenerateNodeGrid(5, 5)
	newBroodling.Pathfinding:GenerateNodeCircle(1, 8, 7, 2)
	
	local DamagedFlash = coroutine.wrap(function()
		while true do
			if not newBroodling.Model then return end
			local CosmeticMain: Highlight = newBroodling.Model.Cosmetic.Main.Highlight
			if not CosmeticMain then return end
			CosmeticMain.Enabled = true
			task.wait(.1)
			CosmeticMain.Enabled = false
			coroutine.yield()
		end
	end)
	newBroodling.OnDamage.Event:Connect(DamagedFlash)
	
	local MainWeld:Weld = newBroodling.PhysicsBound:FindFirstChild("Main")
	local InitWeldPos = MainWeld.C0.Position
	
	local DirectionHandle = RunSer.Stepped:Connect(function()
		if newBroodling.PhysicsBound.AssemblyLinearVelocity.Magnitude < 1 then return end
		MainWeld.C0	= CFrame.new(InitWeldPos, InitWeldPos + newBroodling.PhysicsBound.AssemblyLinearVelocity * Vector3.new(1,0,1))
	end)
	
	local AttackCoro = coroutine.create(function()
		while true do
			task.wait(AttackCooldown)
			local Targets = Entity.GetPlayersInRadius(newBroodling:GetPrimaryPart().Position, AttackRange)
			for _, player: Entity.Entity in Targets do
				player:RecieveAttack(AttackDamage, {})
			end
		end
	end)
	coroutine.resume(AttackCoro)
	
	local PathfingingCoro = coroutine.create(function()
		while true do
			task.wait(.1)
			local NearestPlayer: Entity.Entity = newBroodling:GetNearestPlayer()
			if not NearestPlayer then continue end
			
			newBroodling.Pathfinding:UpdateNodes(newBroodling:GetPrimaryPart().Position ,NearestPlayer:GetPrimaryPart().Position, {newBroodling.Model})
			local Node: Pathfinding.PathfindingNode = newBroodling.Pathfinding:GetLeastWeightNode()
			newBroodling.DirectionOfTravel = Node.Position
		end
	end)
	coroutine.resume(PathfingingCoro)
	
	newBroodling.OnDeath.Event:Connect(function()
		DirectionHandle:Disconnect()
		coroutine.close(AttackCoro)
		coroutine.close(PathfingingCoro)
		
		newBroodling.Pathfinding:Remove()
		newBroodling:Remove()
	end)
	
	return newBroodling
end

function Broodling:Lundge(direction: Vector3)
	self.PhysicsBound.AssemblyLinearVelocity = direction.Unit * LundgeVelocity
end

function Broodling:GetNearestPlayer()
	local playersInRadius = Entity.GetPlayersInRadius(self:GetPrimaryPart().Position, MaxDetectionRange)
	if next(playersInRadius) then
		return playersInRadius[1]
	end
	return nil
end

return Broodling
