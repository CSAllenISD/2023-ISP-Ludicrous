local RepStor = game:GetService("ReplicatedStorage")
local RunSer = game:GetService("RunService")
local SoundSer = game:GetService("SoundService")


local Player = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local Mouse = Player:GetMouse()

UIS.MouseIconEnabled = false

--[[Initialize]]
export type EntityValues = {
	Health: {[string] : {value: number, maxValue: number}},
	Alive: boolean,

	--[[Attack]]
	AttackDamage: FlexValue,
	Resistances: {string:number},
	AttackTypes: {String},

	--[[StatusEffect]]
	StatusEffects: {string:number},

	--[[Movement]]
	MaxWalkSpeed: FlexValue,
	WalkForce: FlexValue,
	JumpForce: FlexValue,
	DragCoefficient: number,
	DragFactor: number,
	DragMidair: boolean,
	MoveMidair: boolean,
	JumpMidair: boolean,
}

print("Initializing")

--[[Character Setup]]
local OnDeath = Instance.new("BindableEvent")

local GetCharacter: RemoteFunction = RepStor.Events.PlayerEntity.GetCharacter
local PlayerModel: Model = GetCharacter:InvokeServer()
for _, instance: BasePart in PlayerModel:GetDescendants() do
	if instance:IsA("BasePart") then
		instance.LocalTransparencyModifier = 1
	end
end

local GetPlayerEntity: RemoteFunction = RepStor.Events.PlayerEntity.GetEntityValues
local PlayerValues: EntityValues = GetPlayerEntity:InvokeServer()

--[[Camera]]--
local CameraPart: BasePart = PlayerModel:FindFirstChild("CameraFocus")
if not CameraPart then warn("PlayerModel missing CamerFocus") return end
Player.CameraMode = Enum.CameraMode.LockFirstPerson

local Camera = workspace.Camera
Camera.CameraType = Enum.CameraType.Custom
Camera.CameraSubject = CameraPart
Camera.FieldOfView = 90

--[[Movement]]
local playerMovementEnabled = true

local FowardKey = Enum.KeyCode.W
local LeftKey = Enum.KeyCode.A
local BackKey = Enum.KeyCode.S
local RightKey = Enum.KeyCode.D

local DashKey = Enum.KeyCode.LeftShift
local GroundPoundKey = Enum.KeyCode.LeftControl
local JumpKey = Enum.KeyCode.Space

local ForwardHeld = false
local BackHeld = false
local RightHeld = false
local LeftHeld = false

local Dashing = false
local GroundPounding = false
local GroundPoundSavedVelocity = Vector3.new(0,0,0)

local OnJump: BindableEvent = Instance.new("BindableEvent")
local OnDash: BindableEvent = Instance.new("BindableEvent")
local OnGroundPound: BindableEvent = Instance.new("BindableEvent")

local movementInputHandle = UIS.InputBegan:Connect(function(input)
	local keyCode = input.KeyCode
	if playerMovementEnabled then
		if keyCode == FowardKey then
			ForwardHeld = true
		elseif keyCode == BackKey then
			BackHeld = true
		elseif keyCode == LeftKey then
			LeftHeld = true
		elseif keyCode == RightKey then
			RightHeld = true
		elseif keyCode == JumpKey then
			OnJump:Fire()
		elseif keyCode == DashKey then
			OnDash:Fire()	
		elseif keyCode == GroundPoundKey then
			OnGroundPound:Fire()
		end
	else
		ForwardHeld = false
		BackHeld = false
		LeftHeld = false
		RightHeld = false
	end
end)

local movementOutputHandle = UIS.InputEnded:Connect(function(input)
	local keyCode = input.KeyCode
	if playerMovementEnabled then
		if keyCode == FowardKey then
			ForwardHeld = false
		elseif keyCode == BackKey then
			BackHeld = false
		elseif keyCode == LeftKey then
			LeftHeld = false
		elseif keyCode == RightKey then
			RightHeld = false
		end
	end
end)

local AxisOfControl = Vector3.new(1,0,1)

local GroundBound: BasePart = PlayerModel:FindFirstChild("GroundBound")
local PhysicsBound: BasePart = PlayerModel:FindFirstChild("PhysicsBound")

local OnGround = false
local function TestOnGround(exlcude: {object: Instance}?)
	if typeof(GroundBound) ~= "Instance" or not GroundBound:IsA("BasePart") then warn("GroundBound is not a BasePart") end
	local overparam = OverlapParams.new()
	local blacklist = exlcude or {}
	table.insert(blacklist, PlayerModel)
	overparam.FilterDescendantsInstances = blacklist
	overparam.FilterType = Enum.RaycastFilterType.Blacklist
	overparam.RespectCanCollide = true
	
	local overlap = workspace:GetPartsInPart(GroundBound, overparam)
	if next(overlap) then OnGround = true else OnGround = false end
end

local function ApplyImpulseOnPlayer(force: number, direction: Vector3?)
	if typeof(PhysicsBound) ~= "Instance" or not PhysicsBound:IsA("BasePart") then warn("PhysicsBound is not a BasePart") return end
	PhysicsBound:ApplyImpulse((direction.Unit or Vector3.new(0,1,0)) * force)
end

local function GetDirectionFromKey()
	local resultVector = Vector3.new(0,0,0)
	if ForwardHeld then resultVector += Vector3.new(0,0,1) end
	if BackHeld then resultVector += Vector3.new(0,0,-1) end
	if RightHeld then resultVector += Vector3.new(1,0,0) end
	if LeftHeld then resultVector += Vector3.new(-1,0,0) end
	return resultVector
end

local function GetAxisFromRelative(camera: Camera)
	local KeyDirection:Vector3 = GetDirectionFromKey()

	local MovementLook = camera.CFrame.LookVector.Unit * KeyDirection.Z
	local MovementRight = camera.CFrame.RightVector.Unit * KeyDirection.X
	local MovementDirection = (MovementLook + MovementRight).Unit * Vector3.new(1,0,1)
	if MovementDirection ~= MovementDirection then return Vector3.new(0,0,0) end
	return MovementDirection.Unit
end

local dashVelocity = 80
local dashDuration = 0.15
local dashCooldown: number = 1
local dashDebounce = false
local DashHandle = OnDash.Event:Connect(function()
	if not dashDebounce and GetDirectionFromKey().Magnitude > 0 then
		dashDebounce = true
		Dashing = true
		SoundSer:PlayLocalSound(SoundSer.Dash)
		local initialMagnitude = PhysicsBound.AssemblyLinearVelocity.Magnitude
		PhysicsBound.AssemblyLinearVelocity = dashVelocity * GetAxisFromRelative(Camera)
		task.wait(dashDuration)
		PhysicsBound.AssemblyLinearVelocity = PhysicsBound.AssemblyLinearVelocity * (initialMagnitude / PhysicsBound.AssemblyLinearVelocity.Magnitude)
		Dashing = false
		dashDebounce = false
	end
end)

local groundPoundVelocity: number = 100
local groundPoundCooldown: number = 1
local groundPoundDebounce = false
local GroundPoundHandle = OnGroundPound.Event:Connect(function()
	if not groundPoundDebounce and not OnGround then
		groundPoundDebounce = true
		GroundPounding = true
		SoundSer:PlayLocalSound(SoundSer.Pound)
		GroundPoundSavedVelocity = PhysicsBound.AssemblyLinearVelocity
		PhysicsBound.AssemblyLinearVelocity = Vector3.new(0,-groundPoundVelocity,0)
		task.wait(groundPoundCooldown)
		groundPoundDebounce	= false
	end
end)

local jumpCooldown: number = .3
local jumpDebounce = false
local JumpHandle = OnJump.Event:Connect(function()
	if not jumpDebounce and (OnGround or PlayerValues.JumpMidair)  then
		jumpDebounce = true
		ApplyImpulseOnPlayer(PlayerValues.JumpForce , Vector3.new(0,1,0))
		task.wait(jumpCooldown)
		jumpDebounce = false
	end
end)

local PlayerMovementHandle: RBXScriptConnection = nil
local function ActivatePlayerMovement()
	print("activating ")
	if PlayerMovementHandle then PlayerMovementHandle:Disconnect() end
	PlayerMovementHandle = RunSer.Stepped:Connect(function(t: number, dt: number)
		TestOnGround()
			
		local velocity = PhysicsBound.AssemblyLinearVelocity
		
		local walkForce = Vector3.new(0,0,0)
		local dragForce = Vector3.new(0,0,0)
		
		if (PlayerValues.DragMidair or OnGround) and not (ForwardHeld or BackHeld or LeftHeld or RightHeld) then --Drag can apply if midair is allowed or when on ground
			local dragForce = PlayerValues.DragCoefficient^PlayerValues.DragFactor * -velocity
			PhysicsBound:ApplyImpulse(dragForce * dt)	
		end

		if PlayerValues.MoveMidair or OnGround then --Movement can apply if midair movement allowed or when on ground
			local MovementDirection = GetAxisFromRelative(Camera)	
			walkForce = (PlayerValues.WalkForce * MovementDirection) + Vector3.new(0, PhysicsBound:GetMass() * workspace.Gravity, 0)			
		end

		if (PhysicsBound.AssemblyLinearVelocity * AxisOfControl).Magnitude <= (PlayerValues.MaxWalkSpeed * AxisOfControl).Magnitude then --Only set velocity when magnitude is lower than max veloctiy
			PhysicsBound:ApplyImpulse(walkForce * dt)
		end
		
		local cameraInfluence =  Camera.CFrame.LookVector * Vector3.new(1,0,1)

		local rotatedCFrame = CFrame.new(PlayerModel.PrimaryPart.Position, PlayerModel.PrimaryPart.Position + cameraInfluence)
		PlayerModel.PrimaryPart.CFrame = PlayerModel.PrimaryPart.CFrame:Lerp(rotatedCFrame, .2)

		local PhysicsWeld = PhysicsBound:FindFirstChildOfClass("Weld")
		local weldCFrame = CFrame.new(PhysicsWeld.C0.Position, PhysicsWeld.C0.Position +  cameraInfluence)
		PhysicsWeld.C0 = PhysicsWeld.C0:Lerp(weldCFrame, .2)
			
		if OnGround and GroundPounding then
			PhysicsBound.AssemblyLinearVelocity = (PhysicsBound.AssemblyLinearVelocity + GroundPoundSavedVelocity) * Vector3.new(1,0,1) + Vector3.new(0,7.5,0)
			GroundPounding = false
			GroundPoundSavedVelocity = Vector3.new(0,0,0)
		end
	end)
end

ActivatePlayerMovement()

--[[Inventory]]
local CycleBackpackKey = Enum.KeyCode.E
local DropCurrentKey = Enum.KeyCode.T
local PickUpItemKey = Enum.KeyCode.Q

local playerBackpackEnabled = true

local CurrentEquippedSlot = 1
local BackpackSize = 3

local BasicPistolMod = require(RepStor.Modules.Inventory.Tool.Gun.BasicPistol)
local AK47Mod = require(RepStor.Modules.Inventory.Tool.Gun.AK47)
local pistol1 = BasicPistolMod.new(Player, {PlayerModel})
local AK47 = AK47Mod.new(Player, {PlayerModel})
local SpellBook = require(RepStor.Modules.Inventory.Tool.Gun.SpellBook)
local SpellBook = SpellBook.new(Player, {PlayerModel})

local Backpack = {pistol1, AK47, SpellBook}
pistol1:Equip()

local ItemPickupRange = 0
local CollectablePickupRange = 0

local function NextTool()
	local CurrentEquippedTool = Backpack[CurrentEquippedSlot]
	local NextTool = Backpack[CurrentEquippedSlot + 1]
	
	print(NextTool)
	if NextTool then
		CurrentEquippedTool:UnEquip()
		CurrentEquippedSlot += 1
		Backpack[CurrentEquippedSlot]:Equip()
	else
		if not next(Backpack) then return end
		CurrentEquippedTool:UnEquip()
		CurrentEquippedSlot = 1
		Backpack[CurrentEquippedSlot]:Equip()
	end
end

local function AddItem(Item)
	if #Backpack >= BackpackSize then
		local CurrentItem =  Backpack[CurrentEquippedSlot]
		CurrentItem:UnEquip()
		--DropItem CurrentITem
		Backpack[CurrentEquippedSlot] = nil
		Backpack[CurrentEquippedSlot] = Item
	else
		table.insert(Backpack, Item)
	end
end

local function RemoveItem(SlotNum: number, dropItem: boolean)
	if SlotNum > BackpackSize or SlotNum < 1 then warn("Backpack index out of range") return end
	local CurrentItem = Backpack[CurrentEquippedSlot]
	
	if dropItem then
		--DropItem
	end
	table.remove(Backpack, SlotNum)
end

local ItemCollisionGroup = "Item"
local ItemOverlapParams = OverlapParams.new()
ItemOverlapParams.CollisionGroup = ItemCollisionGroup

local function PickupItem()
	local ItemsInRange = workspace:GetPartBoundsInRadius(PlayerModel.PrimaryPart.Position, ItemPickupRange, ItemOverlapParams)
	if not ItemsInRange then return end
end

local backpackInputHandle = UIS.InputBegan:Connect(function(input: InputObject)
	local keyCode = input.KeyCode
	if playerBackpackEnabled then
		if keyCode == CycleBackpackKey then
			NextTool()
		elseif keyCode == DropCurrentKey then
			RemoveItem(CurrentEquippedSlot, true)
		elseif keyCode == PickUpItemKey then
			PickupItem()
		end
	end
end)

--[[Gui]]
local PlayerGui = game:GetService("StarterGui").Main:Clone()
PlayerGui.Parent = Player.PlayerGui

local HealthBar = PlayerGui.PlayerValues["HealthBar"]

local function UpdateHealthGui(dt: number)
	local Health = PlayerValues.Health["Health"]
	local Shield = PlayerValues.Health["Shield"]

	if not Health or not Shield then warn("Failed to fetch player Health and Shield") return end

	local ValueText = PlayerGui.PlayerValues["HealthBar"].TextHolder.TextLabel
	local Text = tostring("❤️ " .. Health.value .. "<font size = \"20\"> 🛡 " .. tostring(Shield.value) .. "</font>")	
	ValueText.Text = Text

	local HealthRatio = Health.value / Health.maxValue
	local ShieldRatio = Shield.value / Shield.maxValue

	HealthBar.HealthFill:TweenSize(UDim2.new(HealthRatio,0,1,0), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, dt)
	HealthBar.ShieldFill:TweenSize(UDim2.new(ShieldRatio,0,1,0), Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, dt)
end

local WeaponGui = PlayerGui.Weapon
local BulletTemplate = WeaponGui.BulletTemplate

local BulletGuiSpacing = 10
local function UpdateAmmo(AmmoCount: number)
	for _, gui in WeaponGui.Bullets:GetChildren() do
		gui:Destroy()
	end
	for count = 1, math.min(AmmoCount, 75) do
		local Bullet = BulletTemplate:Clone()
		Bullet.Name = count
		Bullet.Parent = WeaponGui.Bullets
		Bullet.Visible = true
		Bullet.Position = UDim2.new(Bullet.Position.X, UDim.new(Bullet.Position.Y.Scale, -BulletGuiSpacing * (count - 1)))
	end
end

local WeaponCategoryGui = WeaponGui.WeaponCategory
local DecalRepsitory: Folder = RepStor.Assets.Decals.WeaponCategory
local function UpdateCategory(catergoryName: string)
	local WeaponDecal = DecalRepsitory:FindFirstChild(catergoryName)
	if not WeaponDecal or not WeaponDecal:IsA("Decal") then WeaponCategoryGui.Image = nil end --In case where category does not exist, set url to blank
	local DecalURL = WeaponDecal.Texture
	WeaponCategoryGui.Image = DecalURL
end

local function UpdateWeaponValues(dt)
	local CurrentEquippedWeapon = Backpack[CurrentEquippedSlot]
	if not CurrentEquippedWeapon then return end
	
	local AmmoCount = CurrentEquippedWeapon.Ammo
	if AmmoCount and typeof(AmmoCount) == "number" then 
		UpdateAmmo(AmmoCount)
	end
	
	local Category = CurrentEquippedWeapon.Category
	if Category and typeof(Category) == "string" then
		UpdateCategory(Category)
	end
end

local function UpdateStatusEffect(effect: {string: number})
	for _, gui in PlayerGui.StatusEffects.EffectGuis:GetChildren() do
		gui:Destroy()
	end
	for name:string, duration in effect do
		local Gui = RepStor.Assets.StatusEffectGui:FindFirstChild(name)
		if not Gui then return end
		local newGui = Gui:Clone()
		newGui.Parent = PlayerGui.StatusEffects.EffectGuis
		
		newGui.Duration.Text = tostring(math.round(duration * 10) / 10)
	end
end

local function UpdatePlayerValues()
	PlayerValues = GetPlayerEntity:InvokeServer()
end

UpdatePlayerValues()
local updateValuesHandle = RunSer.Stepped:Connect(function(t, dt)
	if PlayerValues.Alive then
		UpdatePlayerValues() --Get current player values
		UpdateStatusEffect(PlayerValues.StatusEffects)
		UpdateHealthGui(dt)
		UpdateWeaponValues(dt)
	end
end)

--[[Player Functions]]
OnDeath.Event:Connect(function()
	PlayerMovementHandle:Disconnect()
	DashHandle:Disconnect()
	JumpHandle:Disconnect()
	GroundPoundHandle:Disconnect()
	updateValuesHandle:Disconnect()
	backpackInputHandle:Disconnect()
	movementInputHandle:Disconnect()
	movementOutputHandle:Disconnect()
end)
