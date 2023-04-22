local ServerStor = game:GetService("ServerStorage")
local RunSer = game:GetService("RunService")
local RepStor = game:GetService("ReplicatedStorage")

local Entity = require(ServerStor.Modules.Entity)
local Pathfinding = require(ServerStor.Modules.Pathfinding)
local HealthValue = require(ServerStor.Modules.Entity.HealthValue)
local Explosion = require(ServerStor.Modules.Misc.Explosion)

local ProjectileCall = RepStor.Events.Projectile.SpawnProjectileServer

local random = Random.new()

local PelletCount = 15
local DetectionRange = 100
local MinAttackDistance = 75
local AttackDamage = 10
local AttackProjectile = RepStor.Modules.ProjectileModules.Projectiles.EnemyPlasmaBall
local GrenadeProjectile = RepStor.Modules.ProjectileModules.Projectiles.Grenade
local AttackCooldown = .3

local GunSpread = Vector2.new(-3,3)

local Dummy = {}
Dummy.__index = Dummy
setmetatable(Dummy, Entity)

function Dummy.new(location: CFrame)
	local newDummy = Entity.new("Capybara")
	setmetatable(newDummy, Dummy)
	
	newDummy.Model:PivotTo(location)
	local SpawnEffect:ParticleEmitter = newDummy:GetPrimaryPart().SpawnEffect.ParticleEmitter
	SpawnEffect:Emit(1)
	
	--[[Initialize Values]]--
	newDummy:SetHealth({HealthValue.new("Health", 750, 750)})
	newDummy.MaxWalkSpeed:SetValue(10)
	newDummy.DragCoefficient = 30
	
	newDummy:CalculateMovementInServer()
	
	newDummy.Pathfinding = Pathfinding.new()
	--newDummy.Pathfinding:GenerateNodeGrid(5, 5)
	newDummy.Pathfinding:GenerateNodeCircle(2, 8, 7, 2)
	
	local Sounds = newDummy:GetPrimaryPart().Sounds
	Sounds.BackgroundMusic:Play()
	
	local EntityGyro = newDummy.PhysicsBound:FindFirstChildOfClass("AlignOrientation")

	local RocketAttackCooldown = 5
	local RocketAttackCoro = coroutine.create(function()
		while true do
			task.wait(RocketAttackCooldown)
			
			local NearestPlayer: Entity.Entity = newDummy:GetNearestPlayer()	
			if not NearestPlayer then continue end
			
			for _ = 1, 3 do
				for count = 1, 2 do
					task.wait(.5)
					local attachment:Attachment = newDummy:GetPrimaryPart():FindFirstChild("Rocket" .. tostring(count))
					if not attachment or not attachment:IsA("Attachment") then continue end

					local ProjectileCFrame = CFrame.new(attachment.WorldPosition, NearestPlayer.PhysicsBound.Position)
					ProjectileCall:Fire(newDummy, RepStor.Modules.ProjectileModules.Projectiles.Capybara_Rocket, ProjectileCFrame, nil, {workspace.Entities.EnemyEntities})
					Sounds.Rocket:Play()
				end
			end
		end
	end)
	coroutine.resume(RocketAttackCoro)
	
	local ShotgunAttackCooldown = 3
	local ShotgunXSpread = Vector2.new(-5, 5)
	local ShotgunYSpread = Vector2.new(-10, 10)
	local ShotgunAttackCoro = coroutine.create(function()
		while true do
			task.wait(ShotgunAttackCooldown)
			
			local NearestPlayer: Entity.Entity = newDummy:GetNearestPlayer()	
			if not NearestPlayer then continue end
			
			if newDummy:TestLineOfSight(NearestPlayer:GetPrimaryPart().Position, NearestPlayer.Model) then 
				for _ = 1 , PelletCount do
					local RandomX = math.rad(random:NextNumber(ShotgunXSpread.X, ShotgunXSpread.Y))
					local RandomY = math.rad(random:NextNumber(ShotgunYSpread.X, ShotgunYSpread.Y))
					local ProjectileCFrame = CFrame.new(newDummy:GetPrimaryPart().CFrame.Position, NearestPlayer.PhysicsBound.Position) * CFrame.Angles(RandomX,RandomY,0)
					ProjectileCall:Fire(newDummy, AttackProjectile, ProjectileCFrame, nil, {workspace.Entities.EnemyEntities})
					Sounds.Shotgun:Play()	
				end
			end

		end
	end)
	coroutine.resume(ShotgunAttackCoro)

	local grenadeCoro = coroutine.create(function()
		while true do
			task.wait(10)
			
			for count = 1, 10 do				
				local attachment: Attachment = newDummy:GetPrimaryPart():FindFirstChild("Mortar" .. tostring(count))
				if not attachment or not attachment:IsA("Attachment") then continue end
				
				task.wait(.3)
				
				local ProjectileCFrame = attachment.WorldCFrame
				ProjectileCall:Fire(newDummy, GrenadeProjectile, ProjectileCFrame, nil, {workspace.Entities.EnemyEntities})
				Sounds.Shot:Play()	
			end		
		end
	end)
	coroutine.resume(grenadeCoro)
	
	local roundCount = 100
	local roundCooldown = .05
	local GunCoro = coroutine.create(function()
		while true do
			task.wait(7.5)
			
			local NearestPlayer: Entity.Entity = newDummy:GetNearestPlayer()	
			if not NearestPlayer then continue end
	
			for _ = 1, roundCount do
				task.wait(roundCooldown)
				
				for count = 1, 2 do
					local attachment: Attachment = newDummy:GetPrimaryPart():FindFirstChild("Barrel" .. tostring(count))
					if not attachment or not attachment:IsA("Attachment") then continue end
					
					local Flash = attachment:FindFirstChildOfClass("ParticleEmitter")
					Flash:Emit(1)
					Sounds.Gun:Play()
					
					local ProjectileCFrame = attachment.WorldCFrame * CFrame.Angles(math.rad(random:NextNumber(GunSpread.X, GunSpread.Y)), math.rad(random:NextNumber(GunSpread.X, GunSpread.Y)), 0)
					ProjectileCall:Fire(newDummy, AttackProjectile, ProjectileCFrame, nil, {workspace.Entities.EnemyEntities})
				end
			end
		end
	end)
	coroutine.resume(GunCoro)
	
	local TweenSer = game:GetService("TweenService")
	
	local FlightHeight = 25
	local flying = false
	local PathfingingCoro = coroutine.create(function()
		while true do
			task.wait(.1)
			
			if not flying and newDummy:GetCurrentHealthValue():GetValue() < 500 then
				local Weld: Weld = newDummy.PhysicsBound.Main
				local Tween = TweenSer:Create(Weld, TweenInfo.new(1), {C0 = CFrame.new(Weld.C0.Position + Vector3.new(0,FlightHeight,0))})
				Tween:Play()
				
				local RotorWeld: Weld = newDummy.Model.Cosmetic.Main.Rotor
				local Rotor = newDummy.Model.Cosmetic.Rotor
				local Bottom: Decal = Rotor.RotorBottom
				Bottom.Transparency = 0
				local Top: Decal = Rotor.RotorTop
				Top.Transparency = 0
				
				local RotateTween = TweenSer:Create(RotorWeld, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, math.huge, true), {C0 = CFrame.new(RotorWeld.C0.Position) * CFrame.Angles(0,math.pi,0)})
				RotateTween:Play()
				
				local 
				
				Sounds.Fly:Play()
				
				flying = true
			end
			
			local NearestPlayer: Entity.Entity = newDummy:GetNearestPlayer()	
			if not NearestPlayer then continue end
			
			newDummy.Pathfinding:UpdateNodes(newDummy.PhysicsBound.Position, NearestPlayer.PhysicsBound.Position, {newDummy.Model})
			local Node: Pathfinding.PathfindingNode = newDummy.Pathfinding:GetLeastWeightNode()
			newDummy.DirectionOfTravel = Node.Position

			if not flying then
				EntityGyro.CFrame = CFrame.new(newDummy.PhysicsBound.Position, NearestPlayer:GetPrimaryPart().Position)
			else
				EntityGyro.CFrame = CFrame.new(newDummy.PhysicsBound.Position, NearestPlayer:GetPrimaryPart().Position - Vector3.new(0,FlightHeight,0))
			end

		end
	end)
	coroutine.resume(PathfingingCoro)
	
	newDummy.OnDamage.Event:Connect(function()
		print("Damaged Dummy")
	end)
	
	newDummy.OnDeath.Event:Connect(function()
		for _, sound: Sound in Sounds:GetChildren() do
			sound:Stop()
		end
		
		coroutine.close(grenadeCoro)
		coroutine.close(ShotgunAttackCoro)
		coroutine.close(RocketAttackCoro)		
		coroutine.close(PathfingingCoro)
		coroutine.close(GunCoro)
		
		Explosion.new(newDummy:GetPrimaryPart().Position, 45)
		
		newDummy.Pathfinding:Remove()
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
