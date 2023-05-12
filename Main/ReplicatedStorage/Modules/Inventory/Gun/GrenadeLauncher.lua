local RepStor = game:GetService("ReplicatedStorage")

local Gun = require(script.Parent)

local AK47 = {}
AK47.__index = AK47
setmetatable(AK47, Gun)

function AK47.new(owner: Player, ignore: {Instance})
	local newAK47: Gun.Gun = Gun.new(script.Name, owner, ignore, "Rifle")

	newAK47.Firerate = 200
	newAK47.Firemode = "Semi" -- "Semi", "Auto"

	newAK47.Ammo = 6
	newAK47.MagSize = 6
	newAK47.Reserve = math.huge

	newAK47.ReloadTime = 3.3

	newAK47.VerticalRecoil = Vector2.new(0,10)
	newAK47.HorizontalRecoil = Vector2.new(-20,20)
	
	newAK47.Projectile = RepStor.Modules.ProjectileModules.Projectiles.Rocket

	newAK47.OnShot.Event:Connect(function()
		newAK47.ViewModel.Model.Main.FirePart.MuzzleFlash:Emit(1)
		newAK47.ViewModel:PlaySound("Fire")
	end)
	
	newAK47.OnReload.Event:Connect(function()
		newAK47.ViewModel:PlaySound("Reload")
	end)

	return newAK47
end

return AK47
