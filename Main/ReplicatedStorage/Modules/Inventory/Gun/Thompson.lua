local RepStor = game:GetService("ReplicatedStorage")
--local AnimationRepo = RepStor.Assets.Animations.Tools.Thompson

local Gun = require(script.Parent)

local Thompson = {}
Thompson.__index = Thompson
setmetatable(Thompson, Gun)

function Thompson.new(owner: Player, ignore: {Instance})
	local newThompson: Gun.Gun = Gun.new(script.Name, owner, ignore, "Rifle")

	newThompson.Firerate = 650
	newThompson.Firemode = "Auto" -- "Semi", "Auto"

	newThompson.Ammo = 20
	newThompson.MagSize = 20
	newThompson.Reserve = math.huge

	newThompson.ReloadTime = 2

	newThompson.VerticalRecoil = Vector2.new(-5,5)
	newThompson.HorizontalRecoil = Vector2.new(-5,5)
	
	newThompson.Projectile = RepStor.Modules.ProjectileModules.Projectiles.Bullet

	newThompson.OnShot.Event:Connect(function()
		newThompson.ViewModel.Model.Main.FirePart.MuzzleFlash:Emit(1)
		--newThompson.ViewModel:PlayAnimation(AnimationRepo.Thompson_Shoot, nil, nil, 5)
		newThompson.ViewModel:PlaySound("Fire")
	end)
	
	newThompson.OnReload.Event:Connect(function()
		newThompson.ViewModel:PlaySound("Reload")
	end)

	return newThompson
end

return Thompson
