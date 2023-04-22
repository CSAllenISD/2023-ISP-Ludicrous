local ServerStor = game:GetService("ServerStorage")
local RunSer = game:GetService("RunService")
local RepStor = game:GetService("ReplicatedStorage")

local Entity = require(ServerStor.Modules.Entity)
local Pathfinding = require(ServerStor.Modules.Pathfinding)
local HealthValue = require(ServerStor.Modules.Entity.HealthValue)

local ProjectileCall = RepStor.Events.Projectile.SpawnProjectileServer

local GodRay = RepStor.Modules.ProjectileModules.Projectiles.GodRay
local GodRayPrime = RepStor.Modules.ProjectileModules.Projectiles.GodRayPrime
local Angel = RepStor.Modules.ProjectileModules.Projectiles.Angel

local random = Random.new()

local PelletCount = 15
local DetectionRange = 100
local MinAttackDistance = 75
local AttackDamage = 10

local Lead = Vector3.new(0,0,0)
	
local Dummy = {}
Dummy.__index = Dummy
setmetatable(Dummy, Entity)

function Dummy.new(location: CFrame)
	local newDummy = Entity.new("BenGod")
	setmetatable(newDummy, Dummy)
	
	newDummy.Model:PivotTo(location)
	
	--[[Initialize Values]]--
	newDummy:SetHealth({HealthValue.new("Health", 100000, 100000)})
	newDummy:AddResistance("Holy", 0, 0)
	newDummy.MaxWalkSpeed:SetValue(0)
	
	local Sounds = newDummy:GetPrimaryPart().Sounds
	Sounds.BackgroundMusic:Play()
	
	local EntityGyro = newDummy.PhysicsBound:FindFirstChildOfClass("AlignOrientation")
	local EntityPositionGyro = newDummy.PhysicsBound:FindFirstChildOfClass("AlignPosition")
	
	EntityPositionGyro.Position = location.Position
	EntityPositionGyro.Enabled = true
	
	local RayPrime = false
	
	local turnRate = 90
	local turnHandle = RunSer.Stepped:Connect(function(t, dt:number)
		EntityPositionGyro.Position = location.Position
		EntityGyro.CFrame = EntityGyro.CFrame * CFrame.Angles(0,math.rad(turnRate * dt),0)
	end)
	
	local SpecialAttackCooldown = 10
	local AngelCoro = coroutine.create(function()
		while true do
			task.wait(SpecialAttackCooldown)	
			
			if RayPrime then continue end
			
			local NearestPlayer: Entity.Entity = newDummy:GetNearestPlayer()
			if not NearestPlayer then continue end
						
			local ProjectileCFrame = CFrame.new(newDummy:GetPrimaryPart().Position,Vector3.new(0,newDummy:GetPrimaryPart().Position.Y,0) + NearestPlayer:GetPrimaryPart().Position * Vector3.new(1,0,1)) 
			
			for angle = 1, 5 do
				ProjectileCall:Fire(newDummy, Angel, ProjectileCFrame * CFrame.Angles(0,math.rad(angle * (360 / 5)),0), nil, {workspace.Entities.EnemyEntities})	
			end
		end
	end)
	coroutine.resume(AngelCoro)
	
	local DirectBlastCooldown = 3
	local DirectShotCoro = coroutine.create(function()
		while true do
			task.wait(DirectBlastCooldown)
			
			if RayPrime then continue end
			
			local NearestPlayer: Entity.Entity = newDummy:GetNearestPlayer()
			if not NearestPlayer then continue end

			local location = NearestPlayer:GetPrimaryPart().Position	
			
			ProjectileCall:Fire(newDummy, GodRay, CFrame.new(newDummy:GetPrimaryPart().Position, NearestPlayer:GetPrimaryPart().Position), nil, {workspace.Entities.EnemyEntities})	
		end
	end)
	coroutine.resume(DirectShotCoro)
	
	local PrimeBlastCooldown = 20
	local PrimeBlastCoro = coroutine.create(function()
		while true do
			task.wait(PrimeBlastCooldown)

			RayPrime = true

			local NearestPlayer: Entity.Entity = newDummy:GetNearestPlayer()
			if not NearestPlayer then continue end

			local location = newDummy.PhysicsBound.Position - Vector3.new(0,-10,0)

			local rayparam = RaycastParams.new()
			rayparam.FilterDescendantsInstances = {workspace.Entities}

			local GroundRay = workspace:Raycast(location, Vector3.new(0,-100,0), rayparam)
			if not GroundRay then continue end

			ProjectileCall:Fire(newDummy, GodRayPrime, CFrame.new(GroundRay.Position, GroundRay.Position + Vector3.new(0,1,0)), nil, {workspace.Entities.EnemyEntities})	
			
			task.wait(6)
			
			RayPrime = false
		end
	end)
	coroutine.resume(PrimeBlastCoro)
	
	local BlastCooldown = 1
	local BlastCoro = coroutine.create(function()
		while true do
			task.wait(BlastCooldown)
			
			if RayPrime then continue end
			
			local NearestPlayer: Entity.Entity = newDummy:GetNearestPlayer()
			if not NearestPlayer then continue end
			
			local location = NearestPlayer:GetPrimaryPart().Position
			
			local rayparam = RaycastParams.new()
			rayparam.FilterDescendantsInstances = {workspace.Entities}
			
			local GroundRay = workspace:Raycast(location, Vector3.new(0,-100,0), rayparam)
			if not GroundRay then continue end
			
			ProjectileCall:Fire(newDummy, GodRay, CFrame.new(GroundRay.Position, GroundRay.Position + Vector3.new(0,1,0)), nil, {workspace.Entities.EnemyEntities})	
		end
	end)
	coroutine.resume(BlastCoro)
	
	newDummy.OnDamage.Event:Connect(function()
		print("Damaged Dummy")
	end)
	
	newDummy.OnDeath.Event:Connect(function()
		for _,v:Sound in Sounds:GetChildren() do
			if not v:IsA("Sound") then continue end
			v:Stop()
		end
		
		--coroutine.close(DirectShotCoro)
		--coroutine.close(AngelCoro)
		coroutine.close(BlastCoro)
		
		newDummy:Remove()
	end)
	
	return newDummy
end


function Dummy:TestLineOfSight(targetLocation: Vector3, Target:Model)
	local EntityLocation = self:GetPrimaryPart().Position

	local rayParam = RaycastParams.new()
	rayParam.FilterDescendantsInstances = {self.Model, Target}
	rayParam.FilterType = Enum.RaycastFilterType.Blacklist

	local testResult = workspace:Raycast(EntityLocation, targetLocation - EntityLocation, rayParam)
	if testResult then return false else return true end
end

function Dummy:GetNearestPlayer()
	local playersInRadius = Entity.GetPlayersInRadius(self:GetPrimaryPart().Position, 500)
	if next(playersInRadius) then
		return playersInRadius[1]
	end
	return nil
end


return Dummy
