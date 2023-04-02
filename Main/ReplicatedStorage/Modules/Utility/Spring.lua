local Spring = {}
Spring.__index = Spring

export type Spring = {
	Postion: number,
	Velocity: number,
	Acceleration: number,
	
	Resistance: number,
	Dampening: number,
	Mass: number,
	
	Shove: (self) -> (),
	Fling: (self) -> (),
	Set: (self) -> (),
	Remove: (self) -> ()
}

function Spring.new(Resistance: number, Dampening: number, Mass: number)
	if typeof(Resistance) ~= "number" then error("SpringResistance is not a number") end
	if typeof(Dampening) ~= "number" then error("SpringDampening is not a number") end
	if typeof(Mass) ~= "number" then error("SpringMass is not a number") end
	
	local newSpring = {}
	setmetatable(newSpring, Spring)
	
	newSpring.Position = 0
	newSpring.Velocity = 0
	newSpring.Acceleration = 0
	
	newSpring.Resistance = Resistance
	newSpring.Dampening = Dampening
	newSpring.Mass = Mass
	
	return newSpring
end

function Spring:Shove(Acceleration: number)
	if typeof(Acceleration) ~= "number" then warn("SpringAcceleration is not a number") return end
	self.Acceleration = Acceleration
end

function Spring:Fling(Velocity: number)
	if typeof(Velocity) ~= "number" then warn("SpringVelocity is not a number") return end
	self.Velocity = Velocity
end

function Spring:Set(Position: number)
	if typeof(Position) ~= "number" then warn("SpringPosition is not a number") return end
	self.Position = Position
end

function Spring:Tick(dt: number)
	if typeof(dt) ~= "number" then warn("SpringTimeDelta is not a number") return end
	
	self.Position = self.Position + (self.Velocity * dt) + (.5 * self.Acceleration * dt^2)
	self.Velocity = self.Velocity + self.Acceleration * dt
	
	local force = -self.Resistance * (self.Position)
	local damping = -self.Dampening * (self.Velocity)
	
	self.Acceleration = (force + damping) / self.Mass
end

function Spring:Remove()
	self.Position = nil
	self.Velocity = nil
	self.Acceleration = nil
	self.Resistance = nil
	self.Dampening = nil
	self.Mass = nil
	
	setmetatable(self, nil)
end

return Spring
