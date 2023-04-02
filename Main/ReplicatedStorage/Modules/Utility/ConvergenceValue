local RunSer = game:GetService("RunService")

local module = {}
module.__index = module

function module.new(initValue:IntValue?, minMaxRange:Vector2, rate:IntValue?)
	local flex = {}
	setmetatable(module, flex)

	flex.value = initValue or 0
	flex.range = minMaxRange or Vector2.new(0,0)
	if flex.range.Y < flex.range.X then
		error("Invalid Flex value range")
	end
	
	flex.rate = rate or 0
	flex.acceleration = 0

	function flex:tick(dt:IntValue)
		if flex.value < 0 then
			flex.value = math.max(flex.range.X ,flex.value + flex.rate * dt + (.5 * flex.acceleration * dt^2))
		elseif flex.value > 0 then
			flex.value = math.min(flex.range.Y, flex.value + flex.rate * dt + (.5 * flex.acceleration * dt^2))
		end
		flex.rate += flex.acceleration * dt	
	end

	local runningTweens = {}

	function flex:tween(amount:IntValue, time:IntValue)
		local rate = amount / time
		local timeElapsed = 0
		local tweenLoop = RunSer.Stepped:Connect(function(dt)
			flex.value += rate * dt
			timeElapsed += dt
		end)
		table.insert(runningTweens, tweenLoop)
		task.wait(time)
		tweenLoop:Disconnect()
		table.remove(table.find(runningTweens, tweenLoop))
	end
	
	function flex:lerp(amount:IntValue)
		if amount >= 0 and amount <= 1 then
			local difference = flex.range.Y - flex.range.X
			flex.value = difference * amount
		else
			error("Flex lerp value exceeds bounds")
		end
	end

	return flex	
end

return module
