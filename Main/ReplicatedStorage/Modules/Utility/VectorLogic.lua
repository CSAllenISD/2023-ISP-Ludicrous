local module = {}

function module:Bounce(initVector:Vector3, normal:Vector3)
 	return initVector - (2 * initVector:Dot(normal) * normal)
end

function module:Penetrate(direction:Vector3, depth:IntValue, rayResult:RaycastResult)
	local overflowRayResult = workspace:Raycast(rayResult.Position + (direction * depth), -direction * depth)
	local penDistance
	if overflowRayResult then
		penDistance = (overflowRayResult.Position - rayResult.Position).Magnitude
	end
	return overflowRayResult, penDistance
end

return module
