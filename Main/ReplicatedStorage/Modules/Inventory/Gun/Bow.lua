local RepStor = game:GetService("ReplicatedStorage")
--local AnimationRepo = RepStor.Assets.Animations.Tools.Bow

local Gun = require(script.Parent)

local Bow = {}
Bow.__index = Bow
setmetatable(Bow, Gun)

function Bow.new(owner: Player, ignore: {Instance})
	local newBow: Gun.Gun = Gun.new(script.Name, owner, ignore, "Rifle")

	newBow.Firerate = 650
	newBow.Firemode = "Semi" -- "Semi", "Auto"

	newBow.Ammo = 1
	newBow.MagSize = 1
	newBow.Reserve = math.huge

	newBow.ReloadTime = .7

	newBow.VerticalRecoil = Vector2.new(-20,20)
	newBow.HorizontalRecoil = Vector2.new(-20,20)
	
	newBow.Projectile = RepStor.Modules.ProjectileModules.Projectiles.Bullet
	newBow.ProjectileArg = {
		Damage = 15
	}
	
	newBow.OnReload.Event:Connect(function()
		task.wait(newBow.ReloadTime)
		newBow.ViewModel.Model.Main.Arrow.Transparency = 0
	end)
	
	newBow.OnShot.Event:Connect(function()
		newBow.ViewModel.Model.Main.Arrow.Transparency = 1
	--	newBow.ViewModel.Model.Main.FirePart.MuzzleFlash:Emit(1)
	--	newBow.ViewModel:PlayAnimation(AnimationRepo.Bow_Shoot, nil, nil, 5)
	--	newBow.ViewModel:PlaySound("Fire")
	end)
	
	newBow.OnReload.Event:Connect(function()
		--newBow.ViewModel:PlaySound("Reload")
	end)

	return newBow
end

return Bow
