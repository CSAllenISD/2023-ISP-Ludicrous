local module = {}

function module.Create(origin:Vector3, endpoint:Vector3, part:BasePart?)
	local diff = (endpoint - origin)
	local center = origin + (diff / 2)
	
	if part then
		part.Size = Vector3.new(part.Size.X,part.Size.Y, diff.Magnitude)
		part.CFrame = CFrame.new(center, endpoint)
	end
end

return module
