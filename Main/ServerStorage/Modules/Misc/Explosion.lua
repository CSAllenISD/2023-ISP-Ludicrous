local Debris = game:GetService("Debris")
local ServerStor = game:GetService("ServerStorage")

local Entity =  require(ServerStor.Modules.Entity)

local part = script.Explosion

local Duration = 1

local Explosion = {}

function Explosion.new(Position: Vector3, Radius: number, PlayerOnly: boolean?)
	if typeof(Position) ~= "Vector3" then warn("ExplosionPosition is not a Vector3") return end
	if typeof(Radius) ~= "number" then warn("ExplosionRadius is not a number") return end
	if PlayerOnly and typeof(PlayerOnly) ~= "boolean" then warn("ExplosionPlayerOnly is not a boolean") return end
	
	local Explosion = part:Clone()
	Explosion.Parent = workspace.Projectiles
	Explosion.Position = Position
	Explosion.Particle.Speed = NumberRange.new(Radius * 5)
	Explosion.Particle:Emit(Radius * 40)
	Explosion.Smoke.Speed = NumberRange.new(Radius * 5)
	Explosion.Smoke:Emit(Radius * 10)
	Explosion.Fire.Speed = NumberRange.new(Radius * 5)
	Explosion.Fire:Emit(Radius * 10)
	Explosion.Sound:Play()
	Debris:AddItem(Explosion, Duration)
	
	if PlayerOnly then
		return Entity.GetPlayersInRadius(Position, Radius)
	else
		return Entity.GetEntitiesInRadius(Position, Radius)
	end
end

return Explosion
