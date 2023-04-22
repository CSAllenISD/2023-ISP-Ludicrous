local ServerStor = game:GetService("ServerStorage")
local RunSer = game:GetService("RunService")
local RepStor = game:GetService("ReplicatedStorage")

local Entity = require(ServerStor.Modules.Entity)
local Pathfinding = require(ServerStor.Modules.Pathfinding)
local HealthValue = require(ServerStor.Modules.Entity.HealthValue)

local ProjectileCall = RepStor.Events.Projectile.SpawnProjectileServer

local MaxDetectionRange = 100

local LundgeVelocity = 50
local LundgeCooldown = 1.5
local LundgeCooldownEnvelope = .5

local AttackRange = 5
local AttackDamage = 10
local AttackCooldown = .5 

local SpitCount = 3
local SpitSpread = 10

local WebCount = 100
local WebSpread = 7.5

local MaxBrood = 10

local random = Random.new()

local Spider = {}
Spider.__index = Spider
setmetatable(Spider, Entity)

function Spider.new(Location: CFrame)
	local newSpider = Entity.new("BroodMother")
	setmetatable(newSpider, Spider)
	newSpider.Model:PivotTo(Location)
		
	newSpider:SetHealth({HealthValue.new("Health", 1000, 1000)})
	newSpider:AddResistance("Fire", 0, 3)
	
	newSpider:CalculateMovementInServer()
	
	newSpider.MaxWalkSpeed:SetValue(3)
	newSpider.WalkForce:SetValue(5000)
	newSpider.DragCoefficient = 30	
	
	newSpider.Pathfinding = Pathfinding.new()
	newSpider.Pathfinding:GenerateNodeCircle(1, 8, 7, 2)
	
	local Regening = false
	
	newSpider.Brood = {}
	
	newSpider.Pivot = newSpider.Model.Cosmetic.Pivot
	
	newSpider.Webbing = false
	
	local Sounds = newSpider:GetPrimaryPart().Sounds
	Sounds.Step:Play()
	Sounds.BackgroundMusic:Play()
	
	local EntityGyro = newSpider.PhysicsBound:FindFirstChildOfClass("AlignOrientation")
	
	local RegenHandle = newSpider.OnDamage.Event:Connect(function(damage: number)
		if not Regening then return end
		local Health: HealthValue.HealthValue = newSpider:GetCurrentHealthValue()
		Health:Add(damage * 2)
	end)
	
	local PathfingingCoro = coroutine.create(function()
		while true do
			task.wait(.1)
			
			if #workspace.Entities.EnemyEntities:GetChildren() >= MaxBrood then
				Regening = true
				newSpider.Model.Cosmetic.Main.Highlight.Enabled = true
			else
				Regening = false
				newSpider.Model.Cosmetic.Main.Highlight.Enabled = false
			end
			
			
			if newSpider.Webbing then newSpider:SetDirectionOfTravel(Vector3.new(0,0,0)) continue end
			local NearestPlayer: Entity.Entity = newSpider:GetNearestPlayer()
			if not NearestPlayer then continue end	
			
			if not Regening then
				EntityGyro.CFrame = CFrame.new(newSpider.PhysicsBound.Position, Vector3.new(0,newSpider.PhysicsBound.Position.Y,0) + NearestPlayer:GetPrimaryPart().Position * Vector3.new(1,0,1))	
			end
			
			newSpider.Pathfinding:UpdateNodes(newSpider.PhysicsBound.Position, NearestPlayer.PhysicsBound.Position, {newSpider.Model})
			local Node: Pathfinding.PathfindingNode = newSpider.Pathfinding:GetLeastWeightNode()
			newSpider:SetDirectionOfTravel(Node.Position)
		end
	end)
	coroutine.resume(PathfingingCoro)
	
	local BroodSpawnCoro = coroutine.create(function()
		while true do
			task.wait(5)
			if #workspace.Entities.EnemyEntities:GetChildren() <= MaxBrood then
				newSpider:SpawnBrood(random:NextUnitVector() * math.random(10, 25))
			end
		end
	end)
	coroutine.resume(BroodSpawnCoro)
	
	local AttackCoro = coroutine.create(function()
		while true do
			task.wait(1)
			
			local NearestPlayer: Entity.Entity = newSpider:GetNearestPlayer()
			if not NearestPlayer then continue end
			
			local randomAttack = random:NextInteger(1, 5)

			if randomAttack == 1 then
				for _ = 1, 3 do
					task.wait(1)
					if #workspace.Entities.EnemyEntities:GetChildren() >= MaxBrood then continue end
					newSpider:SpawnBrood(NearestPlayer:GetPrimaryPart().Position)
				end
			elseif randomAttack == 2 then
				newSpider:WebSpray(NearestPlayer:GetPrimaryPart().Position)
			elseif randomAttack == 3 then
				newSpider:PoisonSpit(NearestPlayer:GetPrimaryPart().Position)
			elseif randomAttack == 4 then
				newSpider:WebSpit(NearestPlayer:GetPrimaryPart())
			elseif randomAttack == 5 then
				newSpider:WebSpray(NearestPlayer:GetPrimaryPart().Position)
			end			
		end
	end)
	coroutine.resume(AttackCoro)
	
	newSpider.OnDamage.Event:Connect(function()
		print("Damaged Spider")
	end)
	
	newSpider.OnDeath.Event:Connect(function()
		for _,v: Instance in Sounds:GetChildren() do
			if not v:IsA("Sound") then continue end
			v:Stop()
		end
		
		coroutine.close(BroodSpawnCoro)
		coroutine.close(PathfingingCoro)
		coroutine.close(AttackCoro)
		
		newSpider.Pivot = nil
		newSpider.Pathfinding:Remove()
		newSpider.Pathfinding = nil
		newSpider:Remove()
	end)
	
	return newSpider
end

local BroodProjectiles = {
	RepStor.Modules.ProjectileModules.Projectiles.BroodlingEgg,
	RepStor.Modules.ProjectileModules.Projectiles.SpitterSpiderEgg,
	RepStor.Modules.ProjectileModules.Projectiles.SpitterSpiderEgg,
	RepStor.Modules.ProjectileModules.Projectiles.SpitterSpiderEgg,
	RepStor.Modules.ProjectileModules.Projectiles.SpitterSpiderEgg,
	RepStor.Modules.ProjectileModules.Projectiles.SpitterSpiderEgg,
	RepStor.Modules.ProjectileModules.Projectiles.SpiderEgg,
	RepStor.Modules.ProjectileModules.Projectiles.SpiderEgg,
	RepStor.Modules.ProjectileModules.Projectiles.SpiderEgg,
	RepStor.Modules.ProjectileModules.Projectiles.SpiderEgg,
	RepStor.Modules.ProjectileModules.Projectiles.SpiderEgg,
	RepStor.Modules.ProjectileModules.Projectiles.SpiderEgg,
	RepStor.Modules.ProjectileModules.Projectiles.SpiderEgg,
	RepStor.Modules.ProjectileModules.Projectiles.SpiderEgg,
	RepStor.Modules.ProjectileModules.Projectiles.SpiderEgg,
}
function Spider:SpawnBrood(targetPos: Vector3)
	local distance = targetPos - self:GetPrimaryPart().Position
	local ProjectileCFrame = CFrame.new(self.Pivot.SpitOrigin.WorldPosition, targetPos + Vector3.new(0,distance.Magnitude * 3,0))
	local randomRotation = CFrame.Angles(math.rad(math.random(-SpitSpread,SpitSpread)), math.rad(math.random(-SpitSpread,SpitSpread)), 0)
	ProjectileCall:Fire(self, BroodProjectiles[random:NextInteger(1, #BroodProjectiles)], ProjectileCFrame * randomRotation, nil, {workspace.Entities.EnemyEntities})
	task.wait(.1)	
end

function Spider:PoisonSpit(targetPos: Vector3)
	local distance = targetPos - self:GetPrimaryPart().Position
	print(distance)
	for _ = 1, SpitCount do
		local ProjectileCFrame = CFrame.new(self.Pivot.SpitOrigin.WorldPosition, targetPos + Vector3.new(0,distance.Magnitude * 3,0))
		local randomRotation = CFrame.Angles(math.rad(math.random(-SpitSpread,SpitSpread)), math.rad(math.random(-SpitSpread,SpitSpread)), 0)
		ProjectileCall:Fire(self, RepStor.Modules.ProjectileModules.Projectiles.PoisonPod, ProjectileCFrame * randomRotation, nil, {workspace.Entities.EnemyEntities})
		task.wait(.1)	
	end
end

function Spider:WebSpit(targetInstance:BasePart)
	for _ = 1, 5 do
		local ProjectileCFrame = CFrame.new(self.Pivot.WebOrigin.WorldPosition, targetInstance.Position)
		local randomRotation = CFrame.Angles(math.rad(math.random(-WebSpread /2,WebSpread / 2)), math.rad(math.random(-WebSpread / 2, WebSpread / 2)), 0)
		ProjectileCall:Fire(self, RepStor.Modules.ProjectileModules.Projectiles.Web, ProjectileCFrame * randomRotation, nil, {workspace.Entities.EnemyEntities})
		task.wait(.1)
	end
end

function Spider:WebSpray(targetPos:Vector3)
	self.Webbing = true
	for _ = 1, WebCount do
		local ProjectileCFrame = CFrame.new(self.Pivot.WebOrigin.WorldPosition, targetPos)
		local randomRotation = CFrame.Angles(math.rad(math.random(-WebSpread,WebSpread)), math.rad(math.random(-WebSpread,WebSpread)), 0)
		ProjectileCall:Fire(self, RepStor.Modules.ProjectileModules.Projectiles.Web, ProjectileCFrame * randomRotation, nil, {workspace.Entities.EnemyEntities})

		task.wait(.05)
	end
	self.Webbing = false
end

function Spider:GetNearestPlayer()
	local playersInRadius = Entity.GetPlayersInRadius(self:GetPrimaryPart().Position, MaxDetectionRange)
	if next(playersInRadius) then
		return playersInRadius[1]
	end
	return nil
end

return Spider
