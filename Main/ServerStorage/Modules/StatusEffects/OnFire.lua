local EffectBaseMod = require(script.Parent)
local Entity = require(script.Parent.Parent)

local Effect = {}
Effect.__index = Effect
setmetatable(Effect, EffectBaseMod)

function Effect.new(OwnerUUID:string, duration: number)
	do
		if typeof(OwnerUUID) ~= "string" then error("ownerUUID is not a string") return end
		if typeof(duration) ~= "number" then error("Duration is not a number") return end	
	end
	
	local newEffect: EffectBaseMod.EffectBase = EffectBaseMod.new(script.Name, OwnerUUID, duration, 0.1)
	setmetatable(newEffect, Effect)
	
	local Count = 0
	newEffect.OnTick.Event:Connect(function(step: number)
		Count += 1
		if Count >= 5 then
			local Entity: Entity.Entity = Entity.GetEntityFromUUID(newEffect.OwnerUUID)
			Entity:RecieveAttack(5, {"Fire"})
			Count = 0
		end
	end)
	
	newEffect.OnRemove.Event:Connect(function()
		print("Effect Stopped!")
	end)
	
	newEffect:Activate()
	return newEffect
end

return Effect

	
