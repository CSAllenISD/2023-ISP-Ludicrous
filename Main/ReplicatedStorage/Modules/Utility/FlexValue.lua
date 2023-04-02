local HttpSer = game:GetService("HttpService")

export type FlexValue = {
	Value: number,
	Multipliers: {number},
	Adders: {number},
	
	SetValue: (self, number) -> (),
	GetRaw: (self) -> (number),
	GetApplied: (self) -> (number),
	AddMultiplier: (self, value:number, time:number) -> (),
	AddAdder: (self, value:number, time:number) -> (),
	Remove: (self) -> ()
}

local Flex = {}
Flex.__index = Flex

function Flex.new(value:number)
	local newFlex = {}
	local runningCoroutines = {}
	
	newFlex.Value = value or 0
	newFlex.Multipliers = {}
	newFlex.Adders = {}
	
	function newFlex:SetValue(value:number)
		if type(value) ~= "number" then warn("Tried to set FlexValue to non number") return end
		newFlex.Value = value
	end
	
	function newFlex:GetRaw()
		return newFlex.Value
	end
	
	function newFlex:GetApplied()
		local modifiedValue = newFlex.Value
		for _,multiplier in newFlex.Multipliers do
			modifiedValue *= multiplier
		end
		for _,adder in newFlex.Adders do
			modifiedValue += adder
		end
		return modifiedValue
	end
	
	function newFlex:AddMultiplier(value:number, t:number?)		
		local UUID = HttpSer:GenerateGUID()
		local newCoro
		if t then 
			newCoro = coroutine.create(function()
				newFlex.Multipliers[UUID] = value
				task.wait(t)
				newFlex.Multipliers[UUID] = nil
			end)
			table.insert(runningCoroutines, newCoro)
			coroutine.resume(newCoro)
		else
			newFlex.Multipliers[UUID] = value
		end
	end	

	function newFlex:AddAdder(value:number, t:number?)		
		local UUID = HttpSer:GenerateGUID()
		local newCoro
		if t then 
			newCoro = coroutine.create(function()
				newFlex.Adders[UUID] = value
				task.wait(t)
				newFlex.Adders[UUID] = nil
			end)
			table.insert(runningCoroutines, newCoro)
			coroutine.resume(newCoro)
		else
			newFlex.Adders[UUID] = value
		end
	end

	function newFlex:Remove()
		for _,coro in runningCoroutines do
			coroutine.close(coro)
		end
		newFlex.Value = nil
		newFlex.Multipliers = nil
		newFlex.Adders = nil
		
		newFlex["SetValue"] = nil
		newFlex["GetRaw"] = nil
		newFlex["GetApplied"] = nil
		newFlex["AddMultiplier"] = nil
		newFlex["AddAdder"] = nil
		newFlex["Remove"] = nil
		setmetatable(newFlex, nil)	
	end
	
	return newFlex
end

return Flex
