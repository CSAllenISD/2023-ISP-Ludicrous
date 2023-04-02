local HttpSer = game:GetService("HttpService")
local RepStor = game:GetService("ReplicatedStorage")
local ServerStor = game:GetService("ServerStorage")
local PlayerSer = game:GetService("Players")
local RunSer = game:GetService("RunService")

local CharacterModelDirectory = ServerStor.Assets.EntityModels

local HealthValue = require(script.HealthValue)
local AttackResistance = require(script.AttackResistance)
local FlexValue = require(RepStor.Modules.Utility.FlexValue)

local StatusEffectBase = require(script.StatusEffectBase)

export type Entity = {
	--[[General]]
	UUID: string,
	Name: string,
	
	GetRawValues: (self) -> (),
	Remove: (self) -> (),
	--[[Player]]
	Player: Player?,	
	AssignPlayer: (self, player: Player) -> (),

	--[[Health]]
	OnDamage: BindableEvent,
	OnDeath: BindableEvent,

	Health: {HealthValue},
	Alive: boolean,

	Death: (self) -> (),
	TestDeath: (self) -> (),
	Reset: (self, initHealthValues: {HealthValue}) -> (),
	SetHealth: (self, newValues: {HealthValue}) -> (),
	GetCurrentHealthValue: (self, priority: number?) -> (HealthValue),
	Damage: (self, Amount: number, priority: number?, overflowValue: boolean?) -> (),
	GetHealthValues: (self) -> ({["Name"]: string, ["Value"]: number}),

	--[[Character]]
	Model: Model,

	GetCharacter: (self) -> (Model),
	Shove: (self, direction: Vector3) -> (),
	PivotTo: (self, CF: CFrame) -> (),

	--[[Attack]]
	OnAttack: BindableEvent,
	AttackDamage: FlexValue,
	HealthAttackPriority: number,
	Resistances: {AttkRes},
	AttackTypes: {String},

	RemoveResistance: (self, name: string) -> (),
	AddResistance: (self, name: string, adder: number, multiplier: number) -> (),
	AttackTarget: (self, TargetEntity: Entity, Amount: number, AttackTypes: {TypeName: string}?) -> (),
	RecieveAttack: (self, Damage: number, AttackTypes: {TypeName: string}?, priority: number?, overflow: boolean?) -> (),
	ApplyAttackModifier: (self, initValue: number, resistanceName: string) -> (number),

	--[[StatusEffect]]
	StatusEffects: {EffectBase},

	GetStatusEffect: (self) -> ({EffectBase}),
	AddStatusEffect: (self, name: string, duration: number, step: number?) -> (),
	RemoveStatusEffect: (self, name: string) -> (),

	--[[Movement]]
	MaxWalkSpeed: FlexValue,
	WalkForce: FlexValue,
	JumpForce: FlexValue,
	DragCoefficient: number,
	DragFactor: number,
	DragMidair: boolean,
	MoveMidair: boolean,
	JumpMidair: boolean,

	DirectionOfTravel: Vector3,
	OnGround: boolean,
	AxisOfControl: Vector3,

	ServerMovement: boolean,

	GroundBound: BasePart,
	PhysicsBound: BasePart,

	CalculateMovementInServer: (self) -> (),
	SetDirectionOfTravel: (self, direction: Vector3) -> (),
	Jump: (self, direction: Vector3) -> (),
	TestOnGround: (self, exclude: {object: Instance}) -> (),	
}


local Entity = {}
Entity.__index = Entity	

Entity.UUIDToEntity = {}
Entity.ModelToEntity = {}
Entity.PlayerToEntity = {}

function Entity.GetEntityFromUUID(UUID: string)
	if typeof(UUID) ~= "string" then warn("EntityUUID is not a string") return end
	local Entity = Entity.UUIDToEntity[UUID]
	if not Entity then warn("Can not find Entity of UUID "..tostring(UUID)) return end
	return Entity
end

function Entity.GetEntityFromModel(Model: Model)
	if typeof(Model) ~= "Instance" or not Model:IsA("Model") then warn("EntityModel is not a Model") return end
	local Entity = Entity.ModelToEntity[Model]
	if not Entity then warn("Can not find Entity of Model", Model) return end
	return Entity
end

function Entity.GetEntityFromPlayer(player: Player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then warn("EntityPlayer is not a player") return end
	local Entity = Entity.PlayerToEntity[player]
	if not Entity then warn("Can not find Entity of Player", player) return end
	return Entity
end

function Entity.GetEntitiesInRadius(origin: Vector3, radius: number)
	if typeof(origin) ~= "Vector3" then warn("EntityBoundOrigin is not a Vector3") return end
	if typeof(radius) ~= "number" then warn("EntityBoundRadius is not a number") return end
	
	local EntitiesInBound = {}
	
	for _, entity: Entity in Entity.UUIDToEntity do
		local EntityModel = entity:GetCharacter()
		local PrimaryPart: BasePart? = EntityModel.PrimaryPart
		local PositionDelta: Vector3 = PrimaryPart.Position - origin
		
		if PositionDelta.Magnitude <= radius then
			table.insert(EntitiesInBound, entity)
		end
	end
	
	table.sort(EntitiesInBound, 
		function(a: Entity, b: Entity)
			return (origin - a.Model.PrimaryPart.Position).Magnitude < (origin - b.Model.PrimaryPart.Position).Magnitude
		end
	)

	return EntitiesInBound
end

function Entity.GetPlayersInRadius(origin: Vector3, radius: number)
	if typeof(origin) ~= "Vector3" then warn("EntityBoundOrigin is not a Vector3") return end
	if typeof(radius) ~= "number" then warn("EntityBoundRadius is not a number") return end
	
	local EntitiesInRadius: {Entity} = Entity.GetEntitiesInRadius(origin, radius)
	local playerEntities = {}
	for _, entity: Entity in EntitiesInRadius do
		if entity.Player then
			table.insert(playerEntities, entity)
		end
	end
	
	table.sort(playerEntities, 
		function(a: Entity, b: Entity)
			return (origin - a.Model.PrimaryPart.Position).Magnitude < (origin - b.Model.PrimaryPart.Position).Magnitude
		end
	)
	
	return playerEntities
end

function Entity.new(name:string)
	if typeof(name) ~= "string" then error("Entity Name is not a string") end
	local newEntity = {}
	setmetatable(newEntity, Entity)
	
	newEntity.Player = nil --Assign Player to use as pointer
	
	newEntity.UUID = HttpSer:GenerateGUID(false) .."-".. HttpSer:GenerateGUID(false) .."-".. HttpSer:GenerateGUID(false)
	Entity.UUIDToEntity[newEntity.UUID] = newEntity --<==
	newEntity.Name = name
	
	--[[Character]]--
	local EntityModel = CharacterModelDirectory:FindFirstChild(name or "Default")
	if not EntityModel then EntityModel = CharacterModelDirectory:FindFirstChild("Default") end
	newEntity.Model = EntityModel:Clone()
	Entity.ModelToEntity[newEntity.Model] = newEntity --<==
	newEntity.Model.Parent = workspace.Entities
	newEntity.Model:PivotTo(CFrame.new(0,10,0))

	local success, response = pcall(function() local _ = newEntity.Model.PrimaryPart end)
	print(success, response)
	if not success then error("EntityModel missing PrimaryPart") end

	--[[Health]]--
	newEntity.OnDamage = Instance.new("BindableEvent")
	newEntity.OnDeath = Instance.new("BindableEvent")
	
	newEntity.Health = { --HealthValue object serves as value holders
		HealthValue.new("Health", 100, 100)
	}
	newEntity.Alive = true
	
	--[[Attack]]--
	newEntity.OnAttack = Instance.new("BindableEvent")
	
	newEntity.AttackDamage = FlexValue.new(0)
	newEntity.HealthAttackPriority = 0
	newEntity.Resistances = {} --Used when recieving damage
	newEntity.AttackTypes = {} --Used when dealing damage
	
	--[[StatusEffect]]--
	newEntity.StatusEffects = {}
	
	--[[Movement]]--
	newEntity.MaxWalkSpeed = FlexValue.new(16)
	newEntity.WalkForce = FlexValue.new(1500)
	newEntity.JumpForce = FlexValue.new(350)
	newEntity.DragCoefficient = 15
	newEntity.DragFactor = 2
	newEntity.DragMidair = false
	newEntity.MoveMidair = false
	newEntity.JumpMidair = false
	
	newEntity.DirectionOfTravel = Vector3.new(0,0,0)
	newEntity.OnGround = false
	newEntity.AxisOfControl = Vector3.new(1,0,1)
	
	newEntity.ServerMovement = false
	
	local groundCollisionPart = newEntity.Model:FindFirstChild("GroundBound")
	if not groundCollisionPart:IsA("BasePart") then error("Could not find BasePart GroundBound in EntityModel") end
	local entityCollisionPart = newEntity.Model:FindFirstChild("PhysicsBound")
	if not entityCollisionPart:IsA("BasePart") then error("Could not find BasePart PhysicsBound in EntityModel") end
	newEntity.GroundBound = groundCollisionPart
	newEntity.PhysicsBound = entityCollisionPart
	
	return newEntity
end

function Entity:GetRawValues()
	local Values = {}
	Values.Health = {}
	for _, value: HealthValue.HealthValue in self.Health do
		Values.Health[value.Name] = {value = value:GetValue(), maxValue = value.Range.Y}
	end
	Values.Alive = self.Alive
	
	Values.AttackDamage = self.AttackDamage:GetApplied()
	Values.Resistances = {}
	for index, Resistance: AttackResistance.AttkRes in self.Resistances do
	 	Values.Resistances[index] = {Resistance.Name, Resistance.Multiplier, Resistance.Adder}
	end
	Values.AttackTypes = self.AttackTypes
	
	Values.StatusEffects = {}
	for _, effect: StatusEffectBase.EffectBase in self.StatusEffects do
		Values.StatusEffects[effect.Name] = effect.RemainingTime
	end
	
	Values.MaxWalkSpeed = self.MaxWalkSpeed:GetApplied()
	Values.WalkForce = self.WalkForce:GetApplied()
	Values.JumpForce = self.JumpForce:GetApplied()
	Values.DragCoefficient = self.DragCoefficient
	Values.DragFactor = self.DragFactor
	Values.DragMidair = self.DragMidair
	Values.MoveMidair = self.MoveMidair
	Values.JumpMidair = self.JumpMidair
	return Values
end

function Entity:Remove()
	if self.MovementHandle then
		self.MovementHandle:Disconnect()
		self.MovementHandle = nil
	end
	
	Entity.UUIDToEntity[self.UUID] = nil
	Entity.ModelToEntity[self.Model] = nil
	if Entity.Player then
		Entity.PlayerToEntity[self.Player] = nil
		Entity.Player = nil	
	end
	
	self.UUID = nil
	self.Name = nil
	self.OnDamage:Destroy()
	self.OnDamage = nil
	self.OnDeath:Destroy()
	self.OnDeath = nil
	
	for _, value: HealthValue.HealthValue in self.Health do
		value:Remove()
	end
	self.Health = nil
	self.Alive = nil
	self.Model:Destroy()
	self.Model = nil
	self.OnAttack:Destroy()
	self.OnAttack = nil
	self.AttackDamage:Remove()
	self.AttackDamage = nil
	self.HealthAttackPriority = nil
	for _, resistance: AttackResistance.AttkRes in self.Resistances do
		resistance:Remove()
	end
	self.Resistances = nil
	self.AttackTypes = nil
	
	for _, effect: StatusEffectBase.EffectBase in self.StatusEffects do
		effect:Remove()
	end
	self.StatusEffects = nil
	
	self.MaxWalkSpeed:Remove()
	self.MaxWalkSpeed = nil
	self.WalkForce:Remove()
	self.WalkForce = nil
	self.JumpForce:Remove()
	self.JumpForce = nil
	self.DragCoefficient = nil
	self.DragFactor = nil
	self.DragMidair = nil
	self.MoveMidair = nil
	self.JumpMidair = nil
	self.DirectionOfTravel = nil
	self.OnGround = nil
	self.AxisOfControl = nil
	self.ServerMovement = nil
	self.GroundBound = nil
	self.PhysicsBound = nil	
	setmetatable(self, nil)
	self = nil
end

--[[Player Functions]]--
function Entity:AssignPlayer(player: Player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then warn("Player is not a player") return end
	if not table.find(PlayerSer:GetPlayers(), player) then warn("Player is not part of Game") return end

	--Set network owner of character to player to let them handle movement
	self.PhysicsBound:SetNetworkOwner(player)

	self.Model.Name = player.Name 
	Entity.PlayerToEntity[player] = self
	self.Player = player
end

--[[Movement]]--

function Entity:CalculateMovementInServer()
	self.ServerMovement = true
	self.MovementHandle = RunSer.Stepped:Connect(function(t: number, dt: number)
		self:TestOnGround() --Test if entity is touching ground		
		
		local velocity = self.PhysicsBound.AssemblyLinearVelocity --fetch velocity of physics part

		local walkForce = Vector3.new(0,0,0) --Initialize force values as 0 magnitude vectors
		local dragForce = Vector3.new(0,0,0)

		if (self.DragMidair or self.OnGround) and self.DirectionOfTravel.Magnitude < 0.01 then --Drag can apply if midair is allowed or when on ground
			local dragForce = self.DragCoefficient^self.DragFactor * -velocity
			self.PhysicsBound:ApplyImpulse(dragForce * dt)
		end
		
		if self.MoveMidair or self.OnGround then --Movement can apply if midair movement allowed or when on ground
			walkForce = self.WalkForce:GetApplied() * self.DirectionOfTravel + Vector3.new(0, self.PhysicsBound:GetMass() * workspace.Gravity, 0)			
		end
		
		if (self.PhysicsBound.AssemblyLinearVelocity * self.AxisOfControl).Magnitude <= (self.MaxWalkSpeed:GetApplied() * self.AxisOfControl).Magnitude then --Only set velocity when magnitude is lower than max veloctiy
			self.PhysicsBound:ApplyImpulse(walkForce * dt)
		end
	end)	
end

function Entity:SetDirectionOfTravel(direction: Vector3)
	if not self.ServerMovement then warn("Movement is not handled by the server") return end
	if not self.Alive then return end
	local direction = direction * self.AxisOfControl
	if direction.Magnitude == 0 then
		self.DirectionOfTravel = Vector3.new(0,0,0)	
	else
		self.DirectionOfTravel = direction.Unit
	end
end

function Entity:Jump(direction: Vector3)
	if not self.ServerMovement then warn("Movement is not handled by the server") return end
	if not self.JumpMidair and not self.OnGround then return end
	if not self.PhysicsBound then warn("Missing EntityPhysicsBound") return end
	local part: BasePart = self.PhysicsBound
	local jumpForce: FlexValue.FlexValue = self.JumpForce
	part:ApplyImpulse((direction.Unit or Vector3.new(0,1,0)) * jumpForce:GetApplied())
end

function Entity:TestOnGround(exclude: {object: Instance}?)
	if not self.ServerMovement then warn("Movement is not handled by the server") return end
	if not self.GroundBound then warn("Missing EntityGroundBound") return end
	local overparam = OverlapParams.new()
	local blacklist = exclude or {}
	table.insert(blacklist, self.Model)
	overparam.FilterDescendantsInstances = blacklist
	overparam.FilterType = Enum.RaycastFilterType.Blacklist
	overparam.RespectCanCollide = true
	
	local overlap = workspace:GetPartsInPart(self.GroundBound, overparam)
	if next(overlap) then self.OnGround = true else self.OnGround = false end
end

--[[StatusEffect]]--
function Entity:GetStatusEffects()
	return self.StatusEffects
end

function Entity:AddStatusEffect(name:string, duration: number, step: number?)
	do
		if typeof(name) ~= "string" then warn("StatusEffectName is not a string") return end
		if typeof(duration) ~= "number" then warn("StatusEffectDuration is not a number") return end
		if step and typeof(step) ~= "number" then warn("StatusEffectArg is not a table") return end
	end
	
	local existingEffect: StatusEffectBase.EffectBase = self.StatusEffects[name]
	if existingEffect then existingEffect:ReApply() return end
	
	local EffectModule: ModuleScript= script.StatusEffectBase:FindFirstChild(name)
	if not EffectModule then warn("EffectModuleScript of name "..tostring(name).." could not be found") return end
	if typeof(EffectModule) ~= "Instance" or not EffectModule:IsA("ModuleScript") then warn("EffectModuleScript is not a ModuleScript") return end
	local Effect: StatusEffectBase.EffectBase =  require(EffectModule).new(self.UUID, duration, step)
	
	local EffectRemoveHandle: RBXScriptConnection
	EffectRemoveHandle = Effect.OnRemove.Event:Connect(function()
		self.StatusEffects[name] = nil
		EffectRemoveHandle:Disconnect()
	end)
	
	self.StatusEffects[name] = Effect
end

function Entity:RemoveStatusEffect(name:string)
	do
		if typeof(name) ~= "string" then warn("StatusEffectName is not a string") return end
	end
	local Effect: StatusEffectBase.EffectBase = self.StatusEffects[name]
	if not Effect then warn("Could not find StatusEffect of name " .. name .. " attached to Entity") return end
	Effect:Remove()
	self.StatusEffects[name] = nil
end

--[[Attack Functions]]--
function Entity:RemoveResistance(name: string)
	do --Parameter type check
		if typeof(name) ~= "string" then warn("ResistanceName is not a string") return end
	end
	
	local resistance: AttackResistance.AttkRes = self.Resistances[name]
	if not resistance then return end
	resistance:Remove()
	self.Resistances[name] = nil
end

function Entity:AddResistance(name: string, adder: number, multiplier: number)
	do --Parameter type check
		if typeof(name) ~= "string" then warn("ResistanceName is not a string") return end
		if typeof(adder) ~= "number" then warn("ResistanceAdder is not a number") return end
		if typeof(multiplier) ~= "number" then warn("ResistanceMultiplier is not a number") return end
	end
	
	self:RemoveResistance(name)
	local newResistance: AttackResistance.AttkRes = AttackResistance.new(name, adder, multiplier)
	self.Resistances[newResistance.Name] = newResistance
end

function Entity:AttackTarget(TargetEntity: Entity, Amount: number, AttackTypes: {TypeName: string}?)
	do --Parameter type check
		if not TargetEntity["RecieveAttack"] then warn("TargetEntity missing method RecieveAttack") return end
		if typeof(Amount) ~= "number" then warn("AttackAmount is not a number") return end	
		if typeof(AttackTypes) ~= "table" then warn("AttackTypes is not a table") return end
		if not next(AttackTypes) then warn("AttackTypes is empty, continuing") end
		for _, TypeName: string in AttackTypes do
			if typeof(TypeName) ~= "string" then warn("AttackTypes contents are not strings") return end
		end
	end
	
	local attackValue: FlexValue.FlexValue = self.AttackDamage:SetValue(Amount)
	TargetEntity:RecieveAttack(attackValue:GetApplied(), AttackTypes or self.AttackTypes, self.HealthAttackPriority)
end

function Entity:RecieveAttack(Damage:number, AttackTypes:{TypeName: string}?, priority: number?, overflow: boolean?)
	do --Parameter type check
		if typeof(Damage) ~= "number" then warn("Damage is not a number") return end
		if priority and typeof(priority) ~= "number" then warn("Priority is not a number") return end
		if type(AttackTypes) ~= "table" then warn	("AttackTypes is not a table") return end
		if overflow and typeof(overflow) ~= "boolean" then warn("Overflow is not a boolean") return end
		
		for _, TypeName: string in AttackTypes do
			if typeof(TypeName) ~= "string" then warn("AttackTypes contents are not strings") return end
		end	
	end
	
	if not AttackTypes then self:Damage(Damage, priority) return end	
	
	local AppliedDamage = Damage
	for _, resistance: string in AttackTypes do
		if type(resistance) ~= "string" then return end
		if self.Resistances[resistance] then
			AppliedDamage = self:ApplyAttackModifier(AppliedDamage, resistance)
		end
	end
	
	self.OnAttack:Fire(Damage, AppliedDamage, AttackTypes)
	self:Damage(AppliedDamage, priority)
end

function Entity:ApplyAttackModifier(initValue: number, resistanceName: string)
	do
		if typeof(initValue) ~= "number" then warn("InitialValue when applying AttackModifier is not number") return end
		if typeof(resistanceName) ~= "string" then warn("ResistanceName is not a string") return end
	end
	
	local finalValue: number = initValue
	
	local Resistance: AttackResistance.AttkRes = self.Resistances[resistanceName]
	if not Resistance then return end
	
	finalValue *= Resistance.Multiplier
	finalValue += Resistance.Adder
	return finalValue
end

--[[Health Functions]]--
function Entity:Death()
	self.Alive = false
	self.Health = {HealthValue.new("Health", 100, 100)}
	self.OnDeath:Fire()
end

function Entity:TestDeath()
	local PrimaryHealthValue: HealthValue.HealthValue = self.Health[1]
	if not PrimaryHealthValue then self:Death() end
	if not PrimaryHealthValue["IsNonZero"] then error("HealthValue missing method IsNonZero") return end
	if not PrimaryHealthValue:IsNonZero() then self:Death() return true end
	return false
end
	
function Entity:Reset(initHealthValues: {HealthValue.HealthValue}?)
	do 
		if initHealthValues then
			if typeof(initHealthValues) ~= "table" then warn("InitialHealthValues is not a table") return end
			for _, value: HealthValue.HealthValue in initHealthValues do
				if not value["Remove"] or not value["ResetValue"] then warn("InitHealthValues does not contain HealthValues") return end
			end
		end
	end
	
	if initHealthValues then 
		for _,Value: HealthValue.HealthValue in self.Health do
			Value:Remove()
		end
		self.Health = initHealthValues
	else
		for _, Value: HealthValue.HealthValue in self.Health do
			Value:ResetValue()
		end
	end
end
	
function Entity:SetHealth(newValues: {HealthValue.HealthValue})
	for priority, value: HealthValue.HealthValue in self.Health do
		value:Remove()
		self.Health[priority] = nil
	end
	self.Health = newValues
end

function Entity:GetCurrentHealthValue(priority: number?)
	do
		if priority and typeof(priority) ~= "number" then warn("Priority is not a number") return end
	end
	
	if not self.Alive then return nil end
	for Priority = (priority or #self.Health), 1, -1 do
		local Value: HealthValue.HealthValue = self.Health[Priority]
		if Value["IsNonZero"] and Value:IsNonZero() then return Value end
	end
	return nil
end

function Entity:Damage(Amount: number, priority: number?, overflowValue: boolean?)
	do
		if typeof(Amount) ~= "number" then warn("DamageAmount is not a number") return end
		if priority and typeof(priority) ~= "number" then warn("DamagePriority is not a number") return end
		if overflowValue and typeof(overflowValue) ~= "boolean" then warn("overflowValue is not a boolean") return end
	end

	local Value: HealthValue.HealthValue = self:GetCurrentHealthValue(priority)
	if not Value then self:Death() return end
	

	local overflow: number = Value:Add(-Amount)
	if overflowValue and overflow then
		for Priority = (priority or #self.Health) - 1, 1, -1 do
			if overflow <= 0 then return end
			local overflowHealthValue: HealthValue.HealthValue = self:GetCurrentHealthValue(Priority)
			overflow = overflowHealthValue:Add(overflow * (Amount / math.abs(Amount)))
		end
	end

	self.OnDamage:Fire(Amount)
	self:TestDeath()
end

function Entity:GetHealthValues()
	local HealthValues = {}
	for priority, Value: HealthValue.HealthValue in self.Health do
		if not Value["Name"] or not Value["Value"] then warn("Invalid HealthValue in Health fetch") continue end
		HealthValues[priority] = {
			["Name"]	 = Value.Name,
			["Value"] = Value:GetValue() 
		}
	end
	return HealthValue
end

--[[Character Functions]]--
function Entity:GetCharacter()
	return self.Model
end

function Entity:GetPrimaryPart()
	local PrimaryPart
	local success, response = pcall(function() PrimaryPart = self.Model.PrimaryPart end)
	if success then return PrimaryPart 
	else warn("EntityModel is missing PrimaryPart") return end
end

function Entity:Shove(direction:Vector3)
	do
		if typeof(direction) ~= "Vector3" then warn("ShoveDirection is not a direction") return end
	end
	
	local primaryPart: BasePart = self:GetPrimaryPart()
	primaryPart:ApplyImpulse(direction)
end

function Entity:PivotTo(CF: CFrame)
	do
		if typeof(CF) ~= "CFrame" then warn("PivotToCF is not a CFrame") return end
	end
	
	local Model:Model = self:GetCharacter()
	Model:PivotTo(CF)
end


return Entity
