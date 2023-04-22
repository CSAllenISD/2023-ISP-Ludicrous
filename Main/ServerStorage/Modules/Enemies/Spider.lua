local ServerStor = game:GetService("ServerStorage")
local RunSer = game:GetService("RunService")

local Entity = require(ServerStor.Modules.Entity)
local Pathfinding = require(ServerStor.Modules.Pathfinding)
local HealthValue = require(ServerStor.Modules.Entity.HealthValue)

local MaxDetectionRange = 100

local LundgeVelocity = 50
local LundgeCooldown = 1.5
local LundgeCooldownEnvelope = .5

local AttackRange = 5
local AttackDamage = 10
local AttackCooldown = .5 
	
local random = Random.new()

local Spider = {}
Spider.__index = Spider
setmetatable(Spider, Entity)

function Spider.new(Location: CFrame)
	local newSpider = Entity.new("Spider")
	setmetatable(newSpider, Spider)
	newSpider.Model:PivotTo(Location)
		
	newSpider:SetHealth({HealthValue.new("Health", 5, 5)})
	newSpider:AddResistance("Fire", 0, 2)
	
	newSpider.MaxWalkSpeed:SetValue(15)
	newSpider.WalkForce:SetValue(3000)
	newSpider.DragCoefficient = 30
	
	newSpider:CalculateMovementInServer()
	
	newSpider.Pathfinding = Pathfinding.new()
	--newSpider.Pathfinding:GenerateNodeGrid(5, 5)
	newSpider.Pathfinding:GenerateNodeCircle(1, 8, 7, 2)
	
	local Sounds:Folder = newSpider:GetPrimaryPart().Sounds
	--print(Sounds)
	Sounds.Step:Play()
		
	local EntityGyro = newSpider.PhysicsBound:FindFirstChildOfClass("AlignOrientation")
		
	local DirectionHandle = RunSer.Stepped:Connect(function()
		if newSpider.DirectionOfTravel.Magnitude <= 0 then return end
		EntityGyro.CFrame = CFrame.new(newSpider.PhysicsBound.Position, newSpider.PhysicsBound.Position + newSpider.DirectionOfTravel * Vector3.new(1,0,1))
	end)
	
	local AttackCoro = coroutine.create(function()
		while true do
			task.wait(AttackCooldown)
			local Targets = Entity.GetPlayersInRadius(newSpider:GetPrimaryPart().Position, AttackRange)
			for _, player: Entity.Entity in Targets do
				player:RecieveAttack(AttackDamage, {})
			end
		end
	end)
	coroutine.resume(AttackCoro)
	
	local lundgeCoro = coroutine.create(function()
		while true do
			task.wait(random:NextNumber(LundgeCooldown - LundgeCooldownEnvelope, LundgeCooldown + LundgeCooldownEnvelope))
			local nearestPlayer: Entity.Entity = newSpider:GetNearestPlayer()
			if not nearestPlayer or not newSpider.OnGround then continue end
			Sounds.Lundge:Play()
			newSpider:Lundge(nearestPlayer:GetPrimaryPart().Position - newSpider:GetPrimaryPart().Position + Vector3.new(0,5,0))
		end
	end)
	coroutine.resume(lundgeCoro)
	
	local PathfingingCoro = coroutine.create(function()
		while true do
			task.wait(.1)
			local NearestPlayer: Entity.Entity = newSpider:GetNearestPlayer()
			if not NearestPlayer then continue end
			newSpider.Pathfinding:UpdateNodes(newSpider:GetPrimaryPart().Position ,NearestPlayer:GetPrimaryPart().Position, {newSpider.Model})
			local Node: Pathfinding.PathfindingNode = newSpider.Pathfinding:GetLeastWeightNode()
			newSpider.DirectionOfTravel = Node.Position
		end
	end)
	coroutine.resume(PathfingingCoro)
	
	
	newSpider.OnDeath.Event:Connect(function()
		for _,v:Instance in Sounds:GetChildren() do
			if not v:IsA("Sound") then continue end
			v:Stop()
		end
		
		DirectionHandle:Disconnect()
		coroutine.close(AttackCoro)
		coroutine.close(PathfingingCoro)
		coroutine.close(lundgeCoro)
		
		newSpider.Pathfinding:Remove()
		newSpider:Remove()
	end)
	
	return newSpider
end

function Spider:Lundge(direction: Vector3)
	self.PhysicsBound.AssemblyLinearVelocity = direction.Unit * LundgeVelocity
end

function Spider:GetNearestPlayer()
	local playersInRadius = Entity.GetPlayersInRadius(self:GetPrimaryPart().Position, MaxDetectionRange)
	if next(playersInRadius) then
		return playersInRadius[1]
	end
	return nil
end

return Spider
