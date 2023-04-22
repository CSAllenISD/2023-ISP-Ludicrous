local ServerStor = game:GetService("ServerStorage")
local RunSer = game:GetService("RunService")
local RepStor = game:GetService("ReplicatedStorage")

local Entity = require(ServerStor.Modules.Entity)
local Pathfinding = require(ServerStor.Modules.Pathfinding)
local HealthValue = require(ServerStor.Modules.Entity.HealthValue)

local MaxDetectionRange = 100

local LundgeVelocity = 50
local LundgeCooldown = 1.5
local LundgeCooldownEnvelope = .5

local AttackRange = 5
local AttackDamage = 10
local AttackCooldown = 1

local SpitProjectile = RepStor.Modules.ProjectileModules.Projectiles.PoisonSpit

local ProjectileCall = RepStor.Events.Projectile.SpawnProjectileServer

local random = Random.new()

local Spider = {}
Spider.__index = Spider
setmetatable(Spider, Entity)

function Spider.new(Location: CFrame)
	local newSpider = Entity.new("PoisonSpitter")
	setmetatable(newSpider, Spider)
	newSpider.Model:PivotTo(Location)
		
	newSpider:SetHealth({HealthValue.new("Health", 10, 10)})
	newSpider:AddResistance("Fire", 0, 2)
	
	newSpider.MaxWalkSpeed:SetValue(3)
	newSpider.WalkForce:SetValue(3000)
	newSpider.DragCoefficient = 30
	
	newSpider:CalculateMovementInServer()
	
	newSpider.Pathfinding = Pathfinding.new()
	--newSpider.Pathfinding:GenerateNodeGrid(5, 5)
	newSpider.Pathfinding:GenerateNodeCircle(1, 16, 7, 2)
	
	local EntityGyro = newSpider.PhysicsBound:FindFirstChildOfClass("AlignOrientation")
	
	local Shooting = false
	local AttackCoro = coroutine.create(function()
		while true do
			task.wait(AttackCooldown)
			
			local NearestPlayer: Entity.Entity = newSpider:GetNearestPlayer()
			if not NearestPlayer then continue end
			
			Shooting = true

			ProjectileCall:Fire(nil, SpitProjectile, CFrame.new(newSpider.Model.Cosmetic.Pivot.SpitOrigin.WorldPosition, NearestPlayer:GetPrimaryPart().Position), nil, {workspace.Entities.EnemyEntities})	

			task.wait(1)
					
			Shooting = false
		end
	end)
	coroutine.resume(AttackCoro)
	
	local PathfingingCoro = coroutine.create(function()
		while true do
			task.wait(.1)
			--if Shooting then continue end
			
			local NearestPlayer: Entity.Entity = newSpider:GetNearestPlayer()
			if not NearestPlayer then continue end
			
			newSpider.Pathfinding:UpdateNodes(newSpider:GetPrimaryPart().Position, NearestPlayer.PhysicsBound.Position, {newSpider.Model})
			local Node: Pathfinding.PathfindingNode = newSpider.Pathfinding:GetLeastWeightNode()
			newSpider.DirectionOfTravel = Node.Position
			
			EntityGyro.CFrame = CFrame.new(newSpider.PhysicsBound.Position, Vector3.new(0,newSpider.PhysicsBound.Position.Y,0) + NearestPlayer.PhysicsBound.Position * Vector3.new(1,0,1))
		end
	end)
	coroutine.resume(PathfingingCoro)
	
	
	newSpider.OnDeath.Event:Connect(function()	
		coroutine.close(AttackCoro)
		coroutine.close(PathfingingCoro)
		
		newSpider.Pathfinding:Remove()
		newSpider:Remove()
	end)
	
	return newSpider
end

function Spider:GetNearestPlayer()
	local playersInRadius = Entity.GetPlayersInRadius(self:GetPrimaryPart().Position, MaxDetectionRange)
	if next(playersInRadius) then
		return playersInRadius[1]
	end
	return nil
end

return Spider
