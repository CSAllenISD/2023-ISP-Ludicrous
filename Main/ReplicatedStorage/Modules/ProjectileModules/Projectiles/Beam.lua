local RunSer = game:GetService("RunService")
local RepStor = game:GetService("ReplicatedStorage")

local Projectile = require(script.Parent.Parent.Projectile)

local BeamModel = script:FindFirstChild(script.Name)
local Rod = require(RepStor.Modules.Utility.Rod)

local BeamVelocity = 10000
local BeamAcceleration = Vector3.new(0,0,0)
local BeamMaxDistance = 100000

local Beam = {}
Beam.__index = Beam
setmetatable(Beam, Projectile)

function Beam.newClient(position: Vector3, direction: Vector3, blacklist: {Instance})
	if not RunSer:IsClient() then error("BeamClient is not in Client") end
	if typeof(position) ~= "Vector3" then error("BeamPosition is not a Vector3") end
	if typeof(direction) ~= "Vector3" then error("BeamDirection is not a Vector3") end
	if typeof(blacklist) ~= "table" then error("BeamBlacklist is not a table") end
	
	local newBeamModel: Model = BeamModel:Clone()
	newBeamModel.Parent = workspace.Projectiles

	local newBeam = Projectile.new(position, direction * BeamVelocity, BeamAcceleration, BeamMaxDistance, blacklist)
	setmetatable(newBeam, Beam)
	
	newBeam.OnEntityHit.Event:Connect(function()
		newBeam:Remove()
	end)
	
	newBeam.OnHit.Event:Connect(function(rayResult: RaycastResult)
		Rod.Create(position, rayResult.Position, newBeamModel.PrimaryPart)
		print(rayResult.Position)
		RunSer.RenderStepped:Wait()
		newBeam:Remove()
	end)
	
	newBeam.OnRemove.Event:Connect(function()
		newBeamModel:Destroy()
	end)
		
	return newBeam
end

function Beam.newServer(position: Vector3, direction: Vector3, blacklist: {Instance})
	if not RunSer:IsServer() then error("BeamServer is not in Server") end
	if typeof(position) ~= "Vector3" then error("BeamPosition is not a Vector3") end
	if typeof(direction) ~= "Vector3" then error("BeamDirection is not a Vector3") end
	if typeof(blacklist) ~= "table" then error("BeamBlacklist is not a table") end
	
	local newBeam = Projectile.new(position, direction * BeamVelocity, BeamAcceleration, BeamMaxDistance, blacklist)
	setmetatable(newBeam, Beam)
	
	newBeam.OnEntityHit.Event:Connect(function(rayResult: RaycastResult, Entity: Entity)
		local EntityMod =  require(game:GetService("ServerStorage").Modules.Entity)
		local DamageEntity: EntityMod.Entity = EntityMod.GetEntityFromUUID(Entity.UUID)
		DamageEntity:RecieveAttack(10, {})
	end)

	newBeam.OnHit.Event:Connect(function(rayResult: RaycastResult)
		print(rayResult.Position)
		newBeam:Remove()
	end)

	return newBeam
end

return Beam
