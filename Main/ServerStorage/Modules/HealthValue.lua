local HealthValue = {}
HealthValue.__index = HealthValue

export type HealthValue = {
	Name:string,
	
	Value: number,
	Range: Vector2,
	Rate: Vector2,
	
	StepTime: number,
	
	ResetValue: (self) -> (),
	IsNonZero: (self) -> (boolean),
	GetValue: (self) -> (number),
	UpdateValue: (self, dt:number) -> (),
	Activate: (self) -> (),
	DeActivate: (self) -> (),
	Add: (self, amount: number) -> (number),
	SetValue: (self, value: number) -> (number),
	Remove: (self) -> (),
	stringSimplify: (self) -> ()
}

function HealthValue.new(Name:string, initVal:number?, maxVal:number?, initRate:Vector2?, stepTime:number?)
	local newValue = {}
	newValue.Name = Name or nil
	
	newValue.Value = initVal or 0
	newValue.Range = Vector3.new(0,maxVal or 100)
	newValue.Rate = initRate or Vector2.new(0,0)

	newValue.StepTime = stepTime or .1

	newValue.StepCoroutine = nil
	
	function newValue:ResetValue()
		newValue.Value = initVal
	end
	
	function newValue:IsNonZero()
		if newValue.Value > 0 then return true else return false end
	end

	function newValue:GetValue()
		return newValue.Value
	end

	function newValue:UpdateValue(dt:number)
		if newValue.StepCoroutine then warn("HealthValue is using Coroutine") return end
		newValue:SetValue(newValue.Value + (newValue.Rate.X * dt) + (.5 * newValue.Rate.Y * dt^2))
		newValue.Rate = Vector2.new(newValue.Rate.X + (newValue.Rate.Y * dt), newValue.Rate.Y)
	end

	function newValue:Activate()
		newValue.StepCoroutine = coroutine.create(function()
			while true do
					newValue:UpdateValue(newValue.StepTime)
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

	function newValue:Add(Amount:number)
		local overflow = newValue:SetValue(newValue.Value + Amount)
		return overflow
	end

	function newValue:SetValue(value:number)
		if not newValue.Range then
			newValue.Value = value
			return
		end
		
		local overflow = 0
		if value < newValue.Range.X then
			newValue.Value = newValue.Range.X
			overflow = value - newValue.Range.X
			
		elseif value > newValue.Range.Y then
			newValue.Value = newValue.Range.Y
			overflow = newValue.Range.Y - value
		else
			newValue.Value = value
		end
		
		return overflow
	end

	function newValue:Remove()
		newValue:DeActivate()
		newValue.Value = nil
		newValue.Range = nil
		newValue.Rate = nil
		newValue.StepCoroutine = nil
		newValue.StepTime = nil		
		newValue.Name = nil
		
		newValue["ResetValue"] = nil
		newValue["IsNonZero"] = nil
		newValue["GetValue"] = nil
		newValue["UpdateValue"] = nil
		newValue["Activate"] = nil
		newValue["DeActivate"] = nil
		newValue["Add"] = nil
		newValue["SetValue"] = nil
	end
	
	function newValue.stringSimplify()
		local returnValue
		local success, response = pcall(function()
			returnValue = "Value("..tostring(newValue.Value)..")\nRange("..tostring(newValue.Range)..")\nRate("..tostring(newValue.Rate)..")\nTime("..tostring(newValue.StepTime)..")"
		end)
		if not success then return "ErrorInValue" end
		return returnValue
	end

	return newValue
end

return HealthValue
