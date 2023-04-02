local RunSer = game:GetService("RunService")
local ServerStor = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local Debug = false

local Proj = {}
Proj.__index = Proj

export type Projectile = {
	OnStep: BindableEvent,
	OnHit: BindableEvent,
	OnEntityHit: BindableEvent,
	OnRemove: BindableEvent,
	
	Position: Vector3,
	Velocity: Vector3,
	Acceleration: Vector3,
	
	MaxDistance: number,
	CurrentDistance: number,
	
	Blacklist: {Instance},
	RaycastParam: RaycastParams,
	
	TickLoop: RBXScriptConnection,
	
	Set: (self, newPosition: Vector3) -> (),
	Fling: (self, newVelocity: Vector3) -> (),
	Shove: (self, newAcceleration: Vector3) -> (),
	SetBlacklist: (self, blacklist: {Instance}) -> (),
	Tick: (self, dt: number) -> (),
	Remove: (self) -> ()
}

function Proj.new(InitPos: Vector3, InitVel: Vector3, InitAccel: Vector3, MaxDistance: number?, ignore: {Instance}?)
	if typeof(InitPos) ~= "Vector3" then error("ProjectilePosition is not a Vector3") end
	if typeof(InitVel) ~= "Vector3" then error("ProjectileVelocity is not a Vector3") end
	if typeof(InitAccel) ~= "Vector3" then error("ProjectileAcceleration is not a Vector3") end
	if MaxDistance and typeof(MaxDistance) ~= "number" then error("ProjectileMaxDistance is not a number") end
	if ignore and typeof(ignore) ~= "table" then error("ProjectileBlacklist is not a table") end
	
	local newProj = {}
	setmetatable(newProj, Proj)
	
	newProj.OnStep = Instance.new("BindableEvent")
	newProj.OnHit = Instance.new("BindableEvent")
	newProj.OnEntityHit = Instance.new("BindableEvent")
	newProj.OnRemove = Instance.new("BindableEvent")
	
	newProj.Position = InitPos
	newProj.Velocity = InitVel
	newProj.Acceleration = InitAccel
	
	newProj.MaxDistance = MaxDistance or 1000
	newProj.CurrentDistance = 0
	
	newProj.Blacklist = {workspace.Debug}
	table.move(ignore,1, #ignore, #newProj.Blacklist + 1, newProj.Blacklist)
	newProj.RaycastParam = RaycastParams.new()
	newProj.RaycastParam.FilterDescendantsInstances = newProj.Blacklist
	newProj.RaycastParam.FilterType = Enum.RaycastFilterType.Blacklist
	
	newProj.Active = true
	
	newProj.TickLoop = nil
	if RunSer:IsClient() then
		newProj.TickLoop = RunSer.RenderStepped:Connect(function(dt: number)
			newProj:Tick(dt)	
		end)	
	elseif RunSer:IsServer() then
		newProj.TickLoop = RunSer.Stepped:Connect(function(t: number, dt: number)
			newProj:Tick(dt)
		end)
	else
		error("Invalid: not Client or Server")		
	end	
	return newProj
end

local TracePart = script.TraceArrow
function Proj:Debug(PositionDelta:Vector3)
	local ArrowClone = TracePart:Clone()
	ArrowClone.Parent = workspace.Debug
	Debris:AddItem(ArrowClone, 3)

	local Position = self.Position + (PositionDelta / 2)
	ArrowClone.Size = Vector3.new(ArrowClone.Size.X, ArrowClone.Size.Y, PositionDelta.Magnitude)
	local Direction = self.Position + self.Velocity
	ArrowClone.CFrame = CFrame.new(Position, Direction)
end

function Proj:Set(newPosition: Vector3)
	if typeof(newPosition) ~= "Vector3" then warn("ProjectilePosition is not a Vector3") return end
	self.Position = newPosition
end

function Proj:Fling(newVelocity: Vector3)
	if typeof(newVelocity) ~= "Vector3" then warn("ProjectileVelocity is not a Vector3") return end
	self.Velocity = newVelocity
end

function Proj:Shove(newAcceleration: Vector3)
	if typeof(newAcceleration) ~= "Vector3" then warn("ProjectileAcceleration is not a Vector3") return end
	self.Acceleration = newAcceleration
end

function Proj:SetBlacklist(blacklist: {Instance})
	if typeof(blacklist) ~= "table" then warn("ProjectileBlacklist is not a table") end
	self.Blacklist = blacklist
	self.RaycastParam.FilterDescendantsInstances = self.Blacklist
end

function Proj:Tick(dt: number)
	if Debug then
		self:Debug(self.Velocity * dt)
	end	
	
	local entityRayParam = RaycastParams.new()
	entityRayParam.CollisionGroup = "HitBox"
	entityRayParam.FilterType = Enum.RaycastFilterType.Blacklist
	entityRayParam.FilterDescendantsInstances = self.Blacklist
	
	local entityRayResult = workspace:Raycast(self.Position, self.Velocity * dt, entityRayParam)
	if entityRayResult then
		local HitPart = entityRayResult.Instance
		if RunSer:IsServer() then
			local Entity = require(game:GetService("ServerStorage").Modules.Entity)

			local Model = HitPart.Parent.Parent
			if not Model:IsA("Model") then return end

			local Entity = Entity.GetEntityFromModel(Model)
			if not Entity then warn("Projectile failed to fetch Entity") return end
			
			self.OnEntityHit:Fire(entityRayResult, Entity)
		end
	end
	
	local rayResult = workspace:Raycast(self.Position, self.Velocity * dt, self.RaycastParam)
	if rayResult then
		self.OnHit:Fire(rayResult)
		return
	end
	
	self.Position = self.Position + (self.Velocity * dt) + (.5 * self.Acceleration * dt^2)
	self.Velocity = self.Velocity + (self.Acceleration * dt)
	
	self.CurrentDistance = self.CurrentDistance + (self.Velocity * dt).Magnitude

	if self.CurrentDistance >= self.MaxDistance then
		self:Remove()
		return
	end
	
	if not self.Active then return end --Test if bullet has been destroyed
	self.OnStep:Fire(dt)
end

function Proj:Remove()
	self.OnRemove:Fire()
	self.Active = nil
	
	self.TickLoop:Disconnect()
	self.TickLoop = nil

	self.OnStep:Destroy()
	self.OnStep = nil
	self.OnEntityHit:Destroy()
	self.OnEntityHit = nil
	self.OnHit:Destroy()
	self.OnHit = nil
	self.OnRemove:Destroy()
	self.OnRemove = nil
	
	self.Position = nil
	self.Velocity = nil
	self.Acceleration = nil
	
	self.MaxDistance = nil
	self.CurrentDistance = nil
	self.Blacklist = nil
	self.RaycastParam = nil
	
	setmetatable(self, nil)
end

return Proj
