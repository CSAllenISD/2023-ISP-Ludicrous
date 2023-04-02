local ModValue = {}
ModValue.__index = ModValue

function ModValue.new(initVal:number?, initRange:Vector2?, initRate:Vector2?, stepTime:number?, pauseTime:number?)
	local newValue = {}
	
	newValue.Value = initVal or 0
	newValue.Range = initRange or nil
	newValue.Rate = initRate or Vector2.new(0,0)
	
	newValue.StepTime = stepTime or .1
	newValue.PauseTime = pauseTime or nil
	newValue.PauseDebounce = false	
	
	newValue.StepCoroutine = nil
	
	function newValue:GetValue()
		return newValue.Value
	end
	
	function newValue:UpdateValue(dt:number)
		if newValue.PauseDebounce and not newValue.StepCoroutine then return end
		newValue:SetValue(newValue.Value + (newValue.Rate.X * dt) + (.5 * newValue.Rate.Y * dt^2))
		newValue.Rate = Vector2.new(newValue.Rate.X + (newValue.Rate.Y * dt), newValue.Rate.Y)
	end
	
	function newValue:Activate()
		newValue.StepCoroutine = coroutine.create(function()
			while true do
				if not newValue.PauseDebounce then
					newValue:UpdateValue(newValue.StepTime)
				end
				task.wait(newValue.StepTime)
			end
		end)
		coroutine.resume(newValue.StepCoroutine)
	end
	
	function newValue:DeActivate()
		if newValue.StepCoroutine then
			coroutine.close(newValue.StepCoroutine)
			newValue.StepCoroutine = nil
		end
	end
	
	function newValue:Add(value:number)
		newValue:SetValue(newValue.Value + value)
		if value < 0 then
			newValue.PauseDebounce = true
			task.wait(newValue.PauseTime)
			newValue.PauseDebounce = false
		end
	end
	
	function newValue:SetValue(value:number)
		if not newValue.Range then
			newValue.Value = value
			return
		end
		if value < newValue.Range.X then
			newValue.Value = newValue.Range.X
		elseif value > newValue.Range.Y then
			newValue.Value = newValue.Range.Y
		else
			newValue.Value = value
		end
	end
	
	function newValue:Remove()
		newValue:DeActivate()
		newValue.Value = nil
		newValue.Range = nil
		newValue.Rate = nil
		newValue.StepCoroutine = nil
		newValue.StepTime = nil	
		newValue.PauseTime = nil	
		newValue.PauseDebounce = nil	
		
		for label,item in newValue do
			if typeof(item) == "Instance" then
				item:Remove()
			elseif typeof(item) == "table" and item["Remove"] then
				item:Remove()
			end
			newValue[label] = nil
		end	
	end
	
	function newValue.stringSimplify()
		local returnValue
		local success, response = pcall(function()
			returnValue = "Value("..tostring(newValue.Value)..")\nRange("..tostring(newValue.Range)..")\nRate("..tostring(newValue.Rate)..")\nTime("..tostring(newValue.StepTime)..":"..tostring(newValue.PauseTime)..")"
		end)
		if not success then return "ErrorInValue" end
		return returnValue
	end
	
	return newValue
end

return ModValue
