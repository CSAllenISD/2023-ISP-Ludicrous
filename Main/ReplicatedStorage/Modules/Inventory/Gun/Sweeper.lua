local RepStor = game:GetService("ReplicatedStorage")

local GunMod = require(script.Parent)

local Gun = {}
Gun.__index = Gun
setmetatable(Gun, GunMod)

function Gun.new(owner: Player, ignore: {Instance})
	local newGun: GunMod.Gun = GunMod.new(script.Name, owner, ignore, "Rifle")

	newGun.Firerate = 130
	newGun.Firemode = "Auto" -- "Semi", "Auto"

	newGun.Ammo = 6
	newGun.MagSize = 6
	newGun.ShotCount = 8
	
	newGun.Reserve = math.huge

	newGun.ReloadTime = 1.3

	newGun.VerticalRecoil = Vector2.new(40,50)
	newGun.HorizontalRecoil = Vector2.new(-20,20)
	newGun.VerticalSpread = Vector2.new(-3,3)
	newGun.HorizontalSpread = Vector2.new(-3,3)
	
	
	newGun.Projectile = RepStor.Modules.ProjectileModules.Projectiles.Bullet
	newGun.ProjectileArg = {Damage = 2}
	
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
