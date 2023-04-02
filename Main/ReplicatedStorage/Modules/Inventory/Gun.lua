local RepStor = game:GetService("ReplicatedStorage")
local RunSer = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local Tool = require(script.Parent)
local ViewModel = require(RepStor.Modules.UI.ViewModel)
local Spring = require(RepStor.Modules.Utility.Spring)

local ProjectileRequest = RepStor.Events.Projectile.SpawnProjectile

local random = Random.new()

local Gun = {}
Gun.__index = Gun
setmetatable(Gun, Tool)

export type Gun = Tool.Tool & {
	OnShot: BindableEvent,
	OnReload: BindableEvent,
	
	Firerate: number,
	Firemode: "Semi" | "Auto",
	
	Category: string,
	Projectile: ModuleScript,
	
	Ammo: number,
	MagSize: number,
	Reservce: number,
	ShotCount: number,
	
	ReloadTime: number,
	Reloading: boolean,
	
	Blacklist: {Instance},
	
	ViewModel: ViewModel.ViewModel,
	
	OrientationSpringX: Spring.Spring,
	OrientationSpringY: Spring.Spring,
	SpringSpeedFactor: number,
	
	VerticalRecoil: Vector2,
	HorizontalRecoil: Vector2,
	
	VerticalSpread: Vector2,
	HorizontalSpread: Vector2,
	
	Shoot: (self) -> (),
	Reload: (self) -> ()
}

function Gun.new(name:string, owner: Player, ignore:{Instance}, category: string, projectile: ModuleScript)
	if typeof(owner) ~= "Instance" or not owner:IsA("Player") then error("ToolOwner is not a player") end
	if typeof(ignore) ~= "table" then error("ToolIgnore is not a table") end
	if not RunSer:IsClient() then error("Tools should be handled in the Client") end

	local newGun: Tool.Tool = Tool.new(owner)
	setmetatable(newGun, Gun)
	newGun.OnShot = Instance.new("BindableEvent")
	newGun.OnReload = Instance.new("BindableEvent")
	
	--[[Attributes]]
	newGun.Projectile = projectile or RepStor.Modules.ProjectileModules.Projectiles.Bullet
	
	newGun.Firerate = 0
	newGun.Firemode = "Semi" -- "Semi", "Auto"

	newGun.Category = category or "Gun"
	
	newGun.Ammo = 0
	newGun.MagSize = 0
	newGun.Reserve = 0
	
	newGun.ShotCount = 1
	newGun.VerticalSpread = Vector2.new(0,0)
	newGun.HorizontalSpread = Vector2.new(0,0)
	
	newGun.VerticalRecoil = Vector2.new(0,0)
	newGun.HorizontalRecoil = Vector2.new(0,0)
	
	newGun.ReloadTime = 0
	newGun.Reloading = false
	newGun.ReloadCoroutine = nil	

	newGun.Blacklist = ignore
	--[[ViewModel]]
	newGun.ViewModel = ViewModel.new(script:FindFirstChild(name):FindFirstChild(name):Clone())
	newGun.ViewModel:Disable()

	newGun.OrientationSpringX = Spring.new(100, 10, 1)
	newGun.OrientationSpringY = Spring.new(100, 10, 1)
	newGun.SpringSpeedFactor = 5
	
	
	local RecoilHandle = RunSer.RenderStepped:Connect(function(dt)
		newGun.OrientationSpringX:Tick(dt)
		newGun.OrientationSpringY:Tick(dt)

		newGun.ViewModel.Offset.Value = CFrame.new(0,0,0) * CFrame.Angles(math.rad(newGun.OrientationSpringY.Position), math.rad(newGun.OrientationSpringX.Position), 0)
	end)	

	--[[Input]]
	local Mouse: Mouse = owner:GetMouse()
	local Camera = workspace.Camera

	local Mouse1Held = false
	local ShootDebounce = false

	--Shooting logic
	local MouseDownHandle = Mouse.Button1Down:Connect(function()
		if not newGun.Equipped then return end
		Mouse1Held = true
		if newGun.Equipped and not ShootDebounce and newGun.Ammo > 0 and not newGun.Reloading then
			ShootDebounce = true
			repeat
				newGun:Shoot(Camera.CFrame.LookVector)	
				task.wait(1 / (newGun.Firerate / 60))
			until not Mouse1Held 
				or newGun.Ammo <= 0 
				or newGun.Reloading 
				or not newGun.Equipped 
				or newGun.Firemode ~= "Auto"
			ShootDebounce = false
		elseif newGun.Ammo <= 0 and not newGun.Reloading then
			newGun:Reload()
		end
	end)
	
	local MouseUpHandle = Mouse.Button1Up:Connect(function()
		if not newGun.Equipped then return end
		Mouse1Held = false
	end)

	--Viewmodel logic
	newGun.OnEquip.Event:Connect(function()
		newGun.ViewModel:Enable()
	end)

	newGun.OnUnEquip.Event:Connect(function()
		local ReloadGui = newGun.Owner.PlayerGui.Main.Reload
		ReloadGui.Stop:Fire()

		newGun.ViewModel:Disable()

		Mouse1Held = false --reset state
		ShootDebounce = false

		if newGun.ReloadCoroutine then --Stop Reloading if reloading
			coroutine.close(newGun.ReloadCoroutine)
		end
		newGun.Reloading = false
	end)

	newGun.OnRemove.Event:Connect(function()
		if newGun.ReloadCoroutine then
			coroutine.close(newGun.ReloadCoroutine)
			local ReloadGui = newGun.Owner.PlayerGui.Main.Reload
			ReloadGui.Stop:Fire()
		end		
		
		newGun.Projectile = nil
		
		newGun.OnShot:Destroy()
		newGun.OnShot = nil
		newGun.OnReload:Destroy()
		newGun.OnReload = nil
		
		newGun.Firerate = nil
		newGun.Firemode = nil
		
		newGun.ShotCount = nil
		newGun.Category = nil
		newGun.Ammo = nil
		newGun.MagSize = nil
		newGun.Reserve = nil
		newGun.ReloadTime = nil
		newGun.Reloading = nil
		newGun.Blacklist = nil
		
		newGun.ViewModel:Remove()
		newGun.ViewModel = nil
		
		newGun.OrientationSpringX:Remove()
		newGun.OrientationSpringX = nil
		newGun.OrientationSpringY:Remove()
		newGun.OrientationSpringY = nil
		
		newGun.VerticalRecoil = nil
		newGun.HorizontalRecoil = nil
		
		newGun.VerticalSpread = nil
		newGun.HorizontalSpread = nil
		
		MouseDownHandle:Disconnect()
		MouseUpHandle:Disconnect()
		RecoilHandle:Disconnect()
		setmetatable(newGun, nil)
	end)
	return newGun
end

local function rotateVectorAround( v, amount, axis )
	return CFrame.fromAxisAngle(axis, amount):VectorToWorldSpace(v)
end

function Gun:Shoot()
	self.OnShot:Fire()
	
	self.Ammo -= 1
		
	local firepart: BasePart = self.ViewModel.Model.Main.FirePart
	for _ = 1, self.ShotCount do
		local randomX = random:NextNumber(self.HorizontalSpread.X, self.HorizontalSpread.Y)
		local randomY = random:NextNumber(self.VerticalSpread.X, self.VerticalSpread.Y)
		local spreadRotation = CFrame.Angles(math.rad(randomY), math.rad(randomX), 0)
		
		ProjectileRequest:FireServer(self.Projectile, workspace.Camera.CFrame * self.ViewModel.Offset.Value * spreadRotation, CFrame.new(firepart.Position, self.Owner:GetMouse().Hit.Position) * self.ViewModel.Offset.Value * spreadRotation, self.Blacklist)
	end
	
	self.OrientationSpringX:Fling(random:NextNumber(self.VerticalRecoil.X,self.VerticalRecoil.Y))
	self.OrientationSpringY:Fling(random:NextNumber(self.HorizontalRecoil.X,self.HorizontalRecoil.Y))
end

function Gun:Reload()
	if self.Reloading or self.Reserve <= 0 then return end
	self.ReloadCoroutine = coroutine.create(function()
		self.OnReload:Fire()
		
		local ReloadGui = self.Owner.PlayerGui.Main.Reload
		ReloadGui.Start:Fire(self.ReloadTime)

		self.Reloading = true
		task.wait(self.ReloadTime)
		local difference = self.MagSize - self.Ammo
		self.Ammo += difference
		self.Reserve -= difference
		self.Reloading = false
	end)
	coroutine.resume(self.ReloadCoroutine)
end


return Gun
