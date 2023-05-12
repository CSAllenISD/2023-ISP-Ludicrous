local RepStor = game:GetService("ReplicatedStorage")

local GunMod = require(script.Parent)

local Gun = {}
Gun.__index = Gun
setmetatable(Gun, GunMod)

function Gun.new(owner: Player, ignore: {Instance})
	local newGun: GunMod.Gun = GunMod.new(script.Name, owner, ignore, "Rifle")

	newGun.Firerate = 130
	newGun.Firemode = "Auto" -- "Semi", "Auto"

	newGun.Ammo = 1
	newGun.MagSize = 1
	
	newGun.Reserve = math.huge

	newGun.ReloadTime = 3.5

	newGun.VerticalRecoil = Vector2.new(10,10)
	newGun.HorizontalRecoil = Vector2.new(-20,20)
	
	newGun.Projectile = RepStor.Modules.ProjectileModules.Projectiles.Rocket
	
	newGun.OnShot.Event:Connect(function()
		newGun.ViewModel.Model.Main.FirePart.MuzzleFlash:Emit(1)
		newGun.ViewModel:PlaySound("Fire")
	end)
	
	newGun.OnReload.Event:Connect(function()
		newGun.ViewModel:PlaySound("Reload")
	end)
	
	return newGun
end

return Gun
