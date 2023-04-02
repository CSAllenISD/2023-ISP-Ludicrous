local RunSer = game:GetService("RunService")

local Projectile = require(script.Parent.Parent.Projectile)

local BulletModel = script:FindFirstChild(script.Name)

local BulletVelocity = 1100
local BulletAcceleration = Vector3.new(0,-50,0)

local Bullet = {}
Bullet.__index = Bullet
setmetatable(Bullet, Projectile)

function Bullet.newClient(position: Vector3, direction: Vector3, blacklist: {Instance})
	if not RunSer:IsClient() then error("BulletClient is not in Client") end
	if typeof(position) ~= "Vector3" then error("BulletPosition is not a Vector3") end
	if typeof(direction) ~= "Vector3" then error("BulletDirection is not a Vector3") end
	if typeof(blacklist) ~= "table" then error("BulletBlacklist is not a table") end
	
	local newBulletModel: Model = BulletModel:Clone()
	newBulletModel.Parent = workspace.Projectiles
	newBulletModel:PivotTo(CFrame.new(position))
	local newBullet = Projectile.new(position, direction * BulletVelocity, BulletAcceleration, nil, blacklist)
	setmetatable(newBullet, Bullet)
	
	newBullet.OnStep.Event:Connect(function(dt: number)
		newBulletModel.PrimaryPart.Transparency = math.max(0, newBulletModel.PrimaryPart.Transparency - dt*5)
		newBulletModel:PivotTo(CFrame.new(newBullet.Position, newBullet.Position + newBullet.Velocity * dt))
	end)
	
	newBullet.OnEntityHit.Event:Connect(function()
		newBullet:Remove()
	end)
	
	newBullet.OnHit.Event:Connect(function(rayResult: RaycastResult)
		newBullet:Remove()
	end)
	
	newBullet.OnRemove.Event:Connect(function()
		newBulletModel:Destroy()
	end)
		
	return newBullet
end

function Bullet.newServer(position: Vector3, direction: Vector3, blacklist: {Instance})
	if not RunSer:IsServer() then error("BulletServer is not in Server") end
	if typeof(position) ~= "Vector3" then error("BulletPosition is not a Vector3") end
	if typeof(direction) ~= "Vector3" then error("BulletDirection is not a Vector3") end
	if typeof(blacklist) ~= "table" then error("BulletBlacklist is not a table") end
	
	local newBullet = Projectile.new(position, direction * BulletVelocity, BulletAcceleration, nil, blacklist)
	setmetatable(newBullet, Bullet)
	
	newBullet.OnEntityHit.Event:Connect(function(rayResult: RaycastResult, Entity: Entity)
		local EntityMod =  require(game:GetService("ServerStorage").Modules.Entity)
		local DamageEntity: EntityMod.Entity = EntityMod.GetEntityFromUUID(Entity.UUID)
		DamageEntity:RecieveAttack(10, {})
	end)

	newBullet.OnHit.Event:Connect(function(rayResult: RaycastResult)
		newBullet:Remove()
	end)

	return newBullet
end

return Bullet
