local RepStor = game:GetService("ReplicatedStorage")

local GunMod = require(script.Parent)

local Gun = {}
Gun.__index = Gun
setmetatable(Gun, GunMod)

function Gun.new(owner: Player, ignore: {Instance})
	local newGun: GunMod.Gun = GunMod.new(script.Name, owner, ignore, "Rifle")

	newGun.Firerate = 650
	newGun.Firemode = "Auto" -- "Semi", "Auto"

	newGun.Ammo = 30
	newGun.MagSize = 30
	
	newGun.Reserve = math.huge

	newGun.ReloadTime = 2.7

	newGun.VerticalRecoil = Vector2.new(20,30)
	newGun.HorizontalRecoil = Vector2.new(-20,20)
	
	newGun.Projectile = RepStor.Modules.ProjectileModules.Projectiles.Bullet
	newGun.ProjectileArg = {Damage = 3}
	
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
