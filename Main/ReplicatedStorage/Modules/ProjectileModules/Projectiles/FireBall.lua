local RunSer = game:GetService("RunService")

local Projectile = require(script.Parent.Parent.Projectile)

local FireBallModel = script:FindFirstChild(script.Name)

local FireBallVelocity = 100
local FireBallMaxDistance = 100
local FireBallAcceleration = Vector3.new(0,-20,0)

local FireBallDamage = 1
local FireBallAttackTypes = {"Fire"}

local FireBall = {}
FireBall.__index = FireBall
setmetatable(FireBall, Projectile)

function FireBall.newClient(position: Vector3, direction: Vector3, blacklist: {Instance})
	if not RunSer:IsClient() then error("FireBallClient is not in Client") end
	if typeof(position) ~= "Vector3" then error("FireBallPosition is not a Vector3") end
	if typeof(direction) ~= "Vector3" then error("FireBallDirection is not a Vector3") end
	if typeof(blacklist) ~= "table" then error("FireBallBlacklist is not a table") end
	
	local newFireBallModel: Model = FireBallModel:Clone()
	newFireBallModel.Parent = workspace.Projectiles
	newFireBallModel:PivotTo(CFrame.new(position))
	local newFireBall = Projectile.new(position, direction * FireBallVelocity, FireBallAcceleration, FireBallMaxDistance, blacklist)
	setmetatable(newFireBall, FireBall)
	
	newFireBall.OnStep.Event:Connect(function(dt: number)
		newFireBallModel:PivotTo(CFrame.new(newFireBall.Position, newFireBall.Position + newFireBall.Velocity * dt))
	end)
	
	newFireBall.OnEntityHit.Event:Connect(function()
		newFireBall:Remove()
	end)
	
	newFireBall.OnHit.Event:Connect(function(rayResult: RaycastResult)
		newFireBall:Remove()
	end)
	
	newFireBall.OnRemove.Event:Connect(function()
		newFireBallModel:Destroy()
	end)
		
	return newFireBall
end

function FireBall.newServer(position: Vector3, direction: Vector3, blacklist: {Instance})
	if not RunSer:IsServer() then error("FireBallServer is not in Server") end
	if typeof(position) ~= "Vector3" then error("FireBallPosition is not a Vector3") end
	if typeof(direction) ~= "Vector3" then error("FireBallDirection is not a Vector3") end
	if typeof(blacklist) ~= "table" then error("FireBallBlacklist is not a table") end
	
	local newFireBall = Projectile.new(position, direction * FireBallVelocity, FireBallAcceleration, FireBallMaxDistance, blacklist)
	setmetatable(newFireBall, FireBall)
	
	newFireBall.OnEntityHit.Event:Connect(function(rayResult: RaycastResult, Entity: Entity)
		local EntityMod =  require(game:GetService("ServerStorage").Modules.Entity)
		local DamageEntity: EntityMod.Entity = EntityMod.GetEntityFromUUID(Entity.UUID)
		DamageEntity:AddStatusEffect("OnFire", 5)
	end)

	newFireBall.OnHit.Event:Connect(function(rayResult: RaycastResult)
		newFireBall:Remove()
	end)

	return newFireBall
end

return FireBall
