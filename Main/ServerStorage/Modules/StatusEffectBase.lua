local EffectBase = {}
EffectBase.__index = EffectBase

export type EffectBase = {
	new: (Duration: number, Step:number?) -> (),
	
	OnTick: BindableEvent ,
	OnRemove: BindableEvent,
	
	Name: string,
	
	OwnerUUID: string,
	Duration: number,
	RemainingTime: number,
	Step: number,
	
	Coroutine: coroutine,
	
	IsRunning: (self) -> (boolean),
	Tick: (self) -> (),
	Activate: (self) -> (),
	ReApply: (self) -> (),
	ModDuration: (self) -> (),
	Remove: (self) -> ()
}

function EffectBase.new(name:string, ownerUUID: string, Duration: number, Step:number?)
	print(ownerUUID)
	do
		if type(name) ~= "string" then error("EffectName is not a string") return end
		if typeof(ownerUUID) ~= "string" then error("ownerUUID is not a string") return end
		if typeof(Duration) ~= "number" then error("Duration is not a number") return end
		if Step and typeof(Step) ~= "number" then error("Step is not a number") return end		
	end
		
	local newEffectBase = {}
	setmetatable(newEffectBase, EffectBase)
	newEffectBase.Name = name
	
	newEffectBase.OwnerUUID = ownerUUID
	newEffectBase.OnTick = Instance.new("BindableEvent")
	newEffectBase.OnRemove = Instance.new("BindableEvent")
	
	newEffectBase.Duration = Duration
	newEffectBase.RemainingTime = Duration
	newEffectBase.Step = Step or .1
	
	newEffectBase.Coroutine = nil
	return newEffectBase
end

function EffectBase:IsRunning()
	if not self.Coroutine then return false end
	if coroutine.status(self.Coroutine) == "running" then return true else return false end
end

function EffectBase:Tick()
	self.RemainingTime -= self.Step
	self.OnTick:Fire(self.Step)
end

function EffectBase:Activate()
	if self.Coroutine then warn("EffectBase already active") return end
	
	self.Coroutine = coroutine.create(function()
		while self.RemainingTime and self.RemainingTime > 0 do
			if not self.RemainingTime then return end
			self:Tick()
			task.wait(self.Step)
		end
		if self.Coroutine then
			self:Remove()
		end
	end)
	coroutine.resume(self.Coroutine)
end

function EffectBase:ReApply()
	self.RemainingTime = self.Duration
end

function EffectBase:ModDuration(amount: number)
	do
		if typeof(amount) ~= "number" then warn("EffectBaseDurationModAmount is not a number") return end
	end
	self.RemainingTime = math.max(0, self.RemainingTIme + amount)
end

function EffectBase:Remove()
	self.OnRemove:Fire()
	self.OwnerUUID = nil
	self.OnTick:Destroy()
	self.OnTick = nil
	self.OnRemove:Destroy()
	self.OnRemove = nil
	
	self.Duration = nil
	self.RemainingTime = nil
	self.Step = nil
	
	if self.Coroutine then
		self.Coroutine = nil
	end
	setmetatable(self, nil)
	self = nil
end

return EffectBase
