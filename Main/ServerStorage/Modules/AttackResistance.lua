local AttkRes = {}
AttkRes.__index = AttkRes

export type AttkRes = {
	Name: string,
	Adder: number,
	Multiplier: number,
	
	Remove: (self) -> ()
}

function AttkRes.new(Name:string, adder: number, multiplier: number)
	if type(Name) ~= "string" then warn("AttackResistance Name is not a string") return end
	if type(adder) ~= "number" then warn("AttackResistance adder is not a number") return end
	if type(multiplier) ~= "number" then warn("AttackResistance multiplier is not a number") return end
	
	local newAttkRes = {}
	newAttkRes.Name = Name
	newAttkRes.Adder = adder
	newAttkRes.Multiplier = multiplier
	
	function newAttkRes:Remove()
		newAttkRes.Name = nil
		newAttkRes.Adder = nil
		newAttkRes.Multiplier = nil
		
		newAttkRes["Remove"] = nil
	end
	
	return newAttkRes
end

return AttkRes
